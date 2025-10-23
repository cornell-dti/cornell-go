import { SessionLogService } from './../session-log/session-log.service';
import { forwardRef, Inject, Injectable } from '@nestjs/common';
import {
  EventBase,
  Group,
  User,
  OrganizationSpecialUsage,
  PrismaClient,
  SessionLogEvent,
  Prisma,
} from '@prisma/client';
import { ClientService } from '../client/client.service';
import { EventService } from '../event/event.service';
import { ChallengeService } from '../challenge/challenge.service';
import { UserService } from '../user/user.service';
import { OrganizationService } from '../organization/organization.service';
import { PrismaService } from '../prisma/prisma.service';
import { GroupDto, GroupInviteDto, UpdateGroupDataDto } from './group.dto';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { subject } from '@casl/ability';
import { Action } from '../casl/action.enum';
import { accessibleBy } from '@casl/prisma';

@Injectable()
export class GroupService {
  constructor(
    private log: SessionLogService,
    private eventService: EventService,
    @Inject(forwardRef(() => UserService))
    private userService: UserService,
    private clientService: ClientService,
    private prisma: PrismaService,
    private abilityFactory: CaslAbilityFactory,
    private challengeService: ChallengeService,
  ) {}

  genFriendlyId() {
    const codes = [];
    for (let i = 0; i < 5; ++i) {
      const val = Math.floor(Math.random() * 35);
      if (val < 26) {
        codes.push(val + 65);
      } else {
        codes.push(val + 22);
      }
    }

    return String.fromCharCode(...codes);
  }

  /** Creates a group from an event and removes from an old group (does delete empty groups) */
  async createFromEvent(event: EventBase): Promise<Group> {
    let code = this.genFriendlyId();

    // Keep trying until one does not collide
    while (
      (await this.prisma.group.count({ where: { friendlyId: code } })) > 0
    ) {
      code = this.genFriendlyId();
    }

    const group: Group = await this.prisma.group.create({
      data: {
        curEventId: event.id,
        friendlyId: code,
        hostId: null,
      },
    });

    console.log(`Group ${code} created!`);

    return group;
  }

  /** Get group of the user */
  async getGroupForUser(user: User): Promise<Group> {
    return await this.prisma.group.findFirstOrThrow({
      where: { members: { some: { id: user.id } } },
    });
  }

  async getGroupById(id: string) {
    return await this.prisma.group.findFirst({
      where: { id },
    });
  }

  /** Get group from by the friendlyId.
   * Throws an error if the id does not correspond to a group. */
  async getGroupFromFriendlyId(id: string): Promise<Group> {
    return await this.prisma.group.findFirstOrThrow({
      where: { friendlyId: id },
    });
  }

  /** Adds user to an existing group, given by the group's id.
   * Checks if user can play the group's current event. If not, does nothing
   * Returns the old group if it still exists, or null. */
  async joinGroup(user: User, joinId: string): Promise<Group | null> {
    return await this.prisma.$transaction(async tx => {
      const oldGroup = await this.getGroupForUser(user);

      const newGroup = await this.prisma.group.findFirstOrThrow({
        where: { friendlyId: joinId.toUpperCase() },
      });

      const isAllowed =
        (await this.prisma.organization.count({
          where: {
            members: { some: { id: user.id } },
            events: { some: { id: newGroup.curEventId } },
          },
        })) > 0;

      if (isAllowed) {
        await this.prisma.group.update({
          where: { friendlyId: joinId.toUpperCase() },
          data: { members: { connect: { id: user.id } } },
        });
        user.groupId = newGroup.id;
        await this.log.logEvent(
          SessionLogEvent.JOIN_GROUP,
          oldGroup.id,
          user.id,
        );
        return await this.fixOrDeleteGroup(oldGroup, tx);
      }
      await this.log.logEvent(SessionLogEvent.JOIN_GROUP, oldGroup.id, user.id);
      return oldGroup;
    });
  }

  /** Moves the user out of their current group into a new group.
   * Returns the old group if it still exists, or null. */
  // create new group
  // move user to new group
  // remove from old
  // fix old
  async leaveGroup(user: User): Promise<Group | null> {
    return await this.prisma.$transaction(async tx => {
      if (!user.groupId) return null;

      //get user's old group
      const oldGroup = await tx.group.findFirstOrThrow({
        where: { id: user.groupId },
        include: { curEvent: true },
      });

      //create new group and make user the host
      const oldFixed = await this.fixOrDeleteGroup(oldGroup, tx);
      const newGroup = await this.createFromEvent(oldGroup.curEvent);

      await tx.group.update({
        where: { id: newGroup.id },
        data: { members: { connect: { id: user.id } } },
      });

      await this.fixOrDeleteGroup(newGroup, tx);
      user.groupId = newGroup.id;

      await this.log.logEvent(
        SessionLogEvent.LEAVE_GROUP,
        oldGroup.id,
        user.id,
      );
      return oldFixed;
    });
  }

  async fixOrDeleteGroup(
    group: Group | { id: string },
    tx: Prisma.TransactionClient,
  ): Promise<Group | null> {
    const oldGroup = await tx.group.findFirstOrThrow({
      where: { id: group.id },
      include: { host: true, members: { take: 1 } },
    });

    if (oldGroup.members.length === 0) {
      // If empty, delete
      await tx.group.delete({ where: { id: group.id } });
      await this.emitUpdateGroupData(oldGroup, true);
      return null;
    } else if (!oldGroup.host && oldGroup.members.length > 0) {
      // If no host, and not empty, replace host
      oldGroup.hostId = oldGroup.members[0].id;
      oldGroup.host = oldGroup.members[0];

      await tx.group.update({
        where: { id: group.id },
        data: { host: { connect: { id: oldGroup.members[0].id } } },
      });
    }

    return oldGroup;
  }

  async getMembers(group: Group | { id: string }) {
    return await this.prisma.user.findMany({
      where: {
        groupId: group.id,
      },
    });
  }

  /**
   * Handles switching events after current event has finished, or if the host
   * selects a new event while current is still active.
   * If host selects a new event, and if eventId is in the allowed
   * events of this group, then updates the group's current event.
   * 
   * If the new event has a timer, starts the timer for the first challenge in the new event
   * for each member of the group.
   *
   * @param actor User that requested the event change, must be a group host
   * @param eventId Id of the event to switch to
   * @returns False if eventId is invalid, otherwise true
   */
  async setCurrentEvent(actor: User, eventId: string) {
    const actorAbility = this.abilityFactory.createForUser(actor);
    const group = await this.prisma.group.findUniqueOrThrow({
      where: { id: actor.groupId },
      include: { curEvent: { select: { endTime: true } }, members: true },
    });

    const stillActive = group.curEvent.endTime.getTime() - Date.now() > 0;

    const newEvent = await this.eventService.getEventById(eventId);

    if (!stillActive || !newEvent) return false;

    // If actor is setting a new event and actor is not host of the group,
    // then this is an invalid set event.
    // If we are only switching an unactive event to a default event,
    // actor and eventId do not matter.

    // Slight hack
    const filteredData = await this.abilityFactory.filterInaccessible(
      group.id,
      { curEventId: group.curEventId },
      'Group',
      actorAbility,
      Action.Update,
      this.prisma.group,
    );

    if (eventId === filteredData.curEventId) {
      return false;
    }

    for (const mem of group.members) {
      const ability = this.abilityFactory.createForUser(mem);
      const canAccess =
        (await this.prisma.eventBase.count({
          where: {
            AND: [
              { id: newEvent.id },
              accessibleBy(ability, Action.Read).EventBase,
            ],
          },
        })) > 0;

      if (!canAccess) {
        return false;
      }
    }

    const groupMembers = await this.getMembers(group);

    await Promise.all(
      groupMembers.map(async (member: User) => {
        await this.eventService.createEventTracker(member, newEvent);

        // Start timer for first challenge in new event if it has a timer length (aka has a timer)
        const tracker = await this.eventService.getCurrentEventTrackerForUser(member);
        if (tracker.curChallengeId) {
          const firstChallenge = await this.challengeService.getChallengeById(tracker.curChallengeId);
          if (firstChallenge?.timerLength) {
            await this.challengeService.startTimer(tracker.curChallengeId, member.id);
          }
        }
      }),
    );

    await this.prisma.group.update({
      where: { id: group.id },
      data: { curEventId: eventId },
    });
    await this.log.logEvent(SessionLogEvent.SELECT_EVENT, eventId, actor.id);
    return true;
  }

  async dtoForGroup(group: Group): Promise<GroupDto> {
    const members = await this.getMembers(group);

    const memberDtos = await Promise.all(
      members.map(async mem => {
        const tracker = await this.eventService.getCurrentEventTrackerForUser(
          mem,
        );
        return {
          id: mem.id,
          name: mem.username,
          points: tracker.score,
          host: mem.id === group.hostId,
          curChallengeId: tracker.curChallengeId ?? undefined,
        };
      }),
    );

    return {
      id: group.id,
      friendlyId: group.friendlyId,
      hostId: group.hostId!,
      curEventId: group.curEventId,
      members: memberDtos,
    };
  }

  async emitUpdateGroupData(group: Group, deleted: boolean, target?: User) {
    const dto: UpdateGroupDataDto = {
      group: deleted ? { id: group.id } : await this.dtoForGroup(group),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateGroupData',
      target ?? group.id,
      dto,
      {
        id: group.id,
        subject: 'Group',
        dtoField: 'group',
        prismaStore: this.prisma.group,
      },
    );
  }

  async emitGroupInvite(group: Group, username: string, user: User) {
    const targetUser = await this.prisma.user.findFirst({
      where: { username: username },
    });

    const dto: GroupInviteDto = {
      groupId: group.friendlyId,
      username: user.username,
    };

    if (targetUser) {
      await this.clientService.sendProtected(
        'groupInvitation',
        targetUser,
        dto,
      );
    } else {
      await this.clientService.emitErrorData(
        user,
        'Group Invitation: User not found',
      );
    }
  }

  async updateGroup(ability: AppAbility, group: GroupDto): Promise<Group> {
    await this.prisma.group.updateMany({
      where: { AND: [{ id: group.id }, accessibleBy(ability).Group] },
      data: await this.abilityFactory.filterInaccessible(
        group.id,
        {
          friendlyId: group.friendlyId,
          hostId: group.hostId,
          curEventId: group.curEventId,
        },
        'Group',
        ability,
        Action.Update,
        this.prisma.group,
      ),
    });

    return (await this.getGroupById(group.id))!;
  }

  /** Helper function that notifies the user, all old group members,
   * and all new members that the user has moved groups. */
  async updateGroupMembers(user: User, oldGroup: Group | null) {
    if (oldGroup) {
      await this.emitUpdateGroupData(oldGroup, false);
      this.clientService.unsubscribe(user, oldGroup.id);
    }

    const newGroup = await this.getGroupForUser(user);
    this.clientService.subscribe(user, newGroup.id);
    await this.emitUpdateGroupData(newGroup, false);
  }

  async removeGroup(ability: AppAbility, removeId: string) {
    const deletedGroup = await this.prisma.group.findFirst({
      where: {
        AND: [{ id: removeId }, accessibleBy(ability, Action.Delete).Group],
      },
      include: { members: true },
    });

    if (!deletedGroup) return false;

    for (const mem of deletedGroup.members) {
      await this.leaveGroup(mem);
      this.clientService.unsubscribe(mem, deletedGroup.id);

      await this.userService.emitUpdateUserData(mem, false, true);
      const group = await this.getGroupForUser(mem);
      await this.emitUpdateGroupData(group, false);
    }

    await this.emitUpdateGroupData(deletedGroup, true);
    await this.clientService.unsubscribeAll(deletedGroup.id);
    await this.prisma.group.delete({ where: { id: removeId } });
  }
}

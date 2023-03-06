import { forwardRef, Inject, Injectable } from '@nestjs/common';
import {
  EventBase,
  Group,
  User,
  OrganizationSpecialUsage,
  PrismaClient,
  Prisma,
} from '@prisma/client';
import { ClientService } from 'src/client/client.service';
import { EventService } from 'src/event/event.service';
import { UserService } from 'src/user/user.service';
import { OrganizationService } from '../organization/organization.service';
import { PrismaService } from '../prisma/prisma.service';
import { GroupDto, UpdateGroupDataDto } from './group.dto';

@Injectable()
export class GroupService {
  constructor(
    private eventService: EventService,
    @Inject(forwardRef(() => UserService))
    private userService: UserService,
    private clientService: ClientService,
    private prisma: PrismaService,
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
        return await this.fixOrDeleteGroup(oldGroup, tx);
      }
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
   * @param actor User that requested the event change, must be a group host
   * @param eventId Id of the event to switch to
   * @returns False if eventId is invalid, otherwise true
   */
  async setCurrentEvent(actor: User, eventId: string) {
    const group = await this.prisma.group.findUniqueOrThrow({
      where: { id: actor.groupId },
      include: { curEvent: { select: { endTime: true } }, members: true },
    });

    const stillActive = group.curEvent.endTime.getTime() - Date.now() > 0;

    let newEvent: EventBase | null = null;

    if (stillActive) {
      // If actor is setting a new event and actor is not host of the group,
      // then this is an invalid set event.
      // If we are only switching an unactive event to a default event,
      // actor and eventId do not matter.
      if (group.hostId !== actor.id || eventId === group.curEventId) {
        return;
      }
      // Uses getAllowedEvents helper method
      const eventIdIntersect = await this.getAllowedEventIds(group);

      if (eventIdIntersect === null || !eventIdIntersect?.includes(eventId))
        return false;

      newEvent = await this.eventService.getEventById(eventId);
    }

    if (!newEvent) return false;

    const groupMembers = await this.getMembers(group);

    await Promise.all(
      groupMembers.map(async (member: User) => {
        await this.eventService.createEventTracker(member, newEvent!);
      }),
    );

    await this.prisma.group.update({
      where: { id: group.id },
      data: { curEventId: eventId },
    });

    return true;
  }

  /**  Finds all allowed events for group based on user's orgs */
  async getAllowedEventIds(group: Group) {
    const users = await this.prisma.user.findMany({
      where: { groupId: group.id },
      select: { memberOf: { include: { events: true } } },
    });

    const uniqueOrgs = Array.from(
      new Set(users.map(user => user.memberOf).flat()),
    );

    const orgIntersect = users.reduce((acc, user) => {
      if (acc.length === 0) {
        return user.memberOf;
      } else {
        return acc.filter(organization => user.memberOf.includes(organization));
      }
    }, uniqueOrgs);

    if (orgIntersect.length === 0) return;

    const eventIdIntersect = Array.from(
      new Set(
        orgIntersect.map(org => org.events.map(event => event.id)).flat(),
      ),
    );
    return eventIdIntersect;
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
          curChallengeId: tracker.curChallengeId,
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

  async emitUpdateGroupData(
    group: Group,
    deleted: boolean,
    admin?: boolean,
    user?: User,
  ) {
    const dto: UpdateGroupDataDto = {
      group: deleted ? group.id : await this.dtoForGroup(group),
      deleted,
    };

    if (user) {
      this.clientService.sendUpdate('updateGroupData', user.id, !!admin, dto);
    } else {
      this.clientService.sendUpdate('updateGroupData', group.id, false, dto);
      this.clientService.sendUpdate('updateGroupData', group.id, true, dto);
    }
  }

  async updateGroup(group: GroupDto): Promise<Group> {
    const groupEntity = await this.prisma.group.update({
      where: { id: group.id },
      data: {
        id: group.id,
        friendlyId: group.friendlyId,
        hostId: group.hostId,
        curEventId: group.curEventId,
      },
    });

    return groupEntity;
  }

  /** Helper function that notifies the user, all old group members,
   * and all new members that the user has moved groups. */
  async updateGroupMembers(user: User, oldGroup: Group | null) {
    if (oldGroup) {
      await this.emitUpdateGroupData(oldGroup, false);
      this.clientService.unsubscribe(user, oldGroup.id, false);
    }

    const newGroup = await this.getGroupForUser(user);
    this.clientService.subscribe(user, newGroup.id, false);
    await this.emitUpdateGroupData(newGroup, false);
  }

  async removeGroup(removeId: string) {
    const deletedGroup = await this.prisma.group.findFirstOrThrow({
      where: { id: removeId },
      include: { members: true },
    });

    for (const mem of deletedGroup.members) {
      await this.leaveGroup(mem);
      this.clientService.unsubscribe(mem, deletedGroup.id, false);
      await this.userService.emitUpdateUserData(mem, false, true, true);
      const group = await this.getGroupForUser(mem);
      await this.emitUpdateGroupData(group, false);
    }

    await this.emitUpdateGroupData(deletedGroup, true, true);
    await this.clientService.unsubscribeAll(deletedGroup.id);
    await this.prisma.group.delete({ where: { id: removeId } });
  }
}

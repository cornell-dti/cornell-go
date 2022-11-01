import { SessionLogService } from './../session-log/session-log.service';
import { Injectable } from '@nestjs/common';
import { EventBase, Group, User, SessionLogEvent, } from '@prisma/client';
import { EventService } from 'src/event/event.service';
import { UpdateGroupDataMemberDto } from '../client/update-group-data.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class GroupService {
  constructor(
    private log: SessionLogService,
    private eventService: EventService,
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
   * Returns the old group if it still exists, or null. */

  async joinGroup(user: User, joinId: string): Promise<Group | null> {
    const oldGroup = await this.getGroupForUser(user);

    const newGroup = await this.prisma.group.update({
      where: { friendlyId: joinId.toUpperCase() },
      data: { members: { connect: { id: user.id } } },
    });

    user.groupId = newGroup.id;

    await this.log.logEvent(SessionLogEvent.JOIN_GROUP, oldGroup.id, user.id);

    return await this.fixOrDeleteGroup(oldGroup);
  }

  /** Moves the user out of their current group into a new group.
   * Returns the old group if it still exists, or null. */
  // create new group
  // move user to new group
  // remove from old
  // fix old
  async leaveGroup(user: User): Promise<Group | null> {
    if (!user.groupId) return null;

    //get user's old group
    const oldGroup = await this.prisma.group.findFirstOrThrow({
      where: { id: user.groupId },
      include: { curEvent: true },
    });

    //create new group and make user the host
    const oldFixed = await this.fixOrDeleteGroup(oldGroup);
    const newGroup = await this.createFromEvent(oldGroup.curEvent);

    await this.prisma.group.update({
      where: { id: newGroup.id },
      data: { members: { connect: { id: user.id } } },
    });

    await this.fixOrDeleteGroup(newGroup);
    user.groupId = newGroup.id;

    await this.log.logEvent(SessionLogEvent.LEAVE_GROUP, oldGroup.id, user.id);

    return oldFixed;
  }

  async fixOrDeleteGroup(group: Group | { id: string }): Promise<Group | null> {
    const oldGroup = await this.prisma.group.findFirstOrThrow({
      where: { id: group.id },
      include: { host: true, members: { take: 1 } },
    });

    // If empty, delete
    if (oldGroup.members.length === 0) {
      await this.prisma.group.delete({ where: { id: group.id } });
      return null;
      // If no host, and not empty, replace host
    } else if (!oldGroup.host && oldGroup.members.length > 0) {
      await this.prisma.group.update({
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

  async setCurrentEvent(actor: User, eventId: string) {
    const group = await this.prisma.group.findUniqueOrThrow({
      where: { id: actor.groupId },
      include: { curEvent: { select: { endTime: true } } },
    });

    const stillActive = group.curEvent.endTime.getTime() - Date.now() > 0;

    if (
      (group.hostId !== actor.id || eventId === group.curEventId) &&
      stillActive
    ) {
      return;
    }

    const newEvent = !stillActive
      ? await this.eventService.getDefaultEvent()
      : await this.eventService.getEventById(eventId);

    if (!newEvent) return;

    const groupMembers = await this.getMembers(group);

    await Promise.all(
      groupMembers.map(async (member: User) => {
        await this.eventService.createEventTracker(member, newEvent);
      }),
    );

    await this.prisma.group.update({
      where: { id: group.id },
      data: { curEventId: eventId },
    });

    await this.log.logEvent(SessionLogEvent.SELECT_EVENT, eventId, actor.id);

    return groupMembers;
  }


  async dtoForMemberData(group: Group): Promise<UpdateGroupDataMemberDto[]> {
    const members = await this.getMembers(group);

    return await Promise.all(
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
  }

}
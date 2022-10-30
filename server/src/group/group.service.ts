import { SessionLogService } from './../session-log/session-log.service';
import { EventService } from 'src/event/event.service';
import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { UserService } from '../user/user.service';
import {
  EventBase,
  Group,
  PrismaClient,
  SessionLogEvent,
  User,
} from '@prisma/client';
import { connect } from 'http2';
import { hostname } from 'os';
import { group } from 'console';
import { join } from 'path';
import { UpdateGroupDataMemberDto } from '../client/update-group-data.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class GroupService {
  constructor(
    private log: SessionLogService,
    private eventService: EventService,
    private prisma: PrismaService,
  ) {}

  /** Creates a group from an event and removes from an old group (does delete empty groups) */
  async createFromEvent(event: EventBase): Promise<Group> {
    const group: Group = await this.prisma.group.create({
      data: {
        curEventId: event.id,
        friendlyId: '',
        hostId: null,
      },
    });

    group.friendlyId = group.id.substring(9, 13);
    return group;
  }

  /** Get group of the user */
  async getGroupForUser(user: User): Promise<Group> {
    return await this.prisma.group.findFirstOrThrow({
      where: { members: { some: user } },
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

  async joinGroup(user: User, joinId: string): Promise<Group | undefined> {
    const oldGroup = await this.getGroupForUser(user);

    await this.prisma.group.update({
      where: { id: joinId },
      data: { members: { connect: user } },
    });

    await this.fixOrDeleteGroup(oldGroup);

    await this.log.logEvent(SessionLogEvent.JOIN_GROUP, oldGroup.id, user.id);

    return oldGroup;
  }

  /** Moves the user out of their current group into a new group.
   * Returns the old group if it still exists, or null. */
  // create new group
  // move user to new group
  // remove from old
  // fix old
  async leaveGroup(user: User): Promise<Group | undefined> {
    if (!user.groupId) return;

    //get user's old group
    const oldGroup = await this.prisma.group.findFirstOrThrow({
      where: { id: user.groupId },
      include: { curEvent: true },
    });

    //create new group and make user the host
    const newGroup = await this.createFromEvent(oldGroup.curEvent);

    await this.prisma.group.update({
      where: { id: newGroup.id },
      data: { hostId: user.id, members: { connect: user } },
    });

    //remove user from old group
    await this.prisma.group.update({
      where: { id: oldGroup.id },
      data: { members: { disconnect: user } },
    });

    await this.log.logEvent(SessionLogEvent.LEAVE_GROUP, oldGroup.id, user.id);

    return oldGroup;
  }

  async fixOrDeleteGroup(group: Group | { id: string }) {
    const oldGroup = await this.prisma.group.findFirstOrThrow({
      where: { id: group.id },
      select: { host: true, members: true },
    });

    // If empty, delete
    if (oldGroup.members.length === 0) {
      await this.prisma.group.delete({ where: { id: group.id } });
      // If no host, and not empty, replace host
    } else if (!oldGroup.host && oldGroup.members.length > 0) {
      await this.prisma.group.update({
        where: { id: group.id },
        data: { host: { connect: oldGroup.members.at(0) } },
      });
    }
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
}

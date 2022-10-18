import { EventService } from 'src/event/event.service';
import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { UserService } from '../user/user.service';
import { EventBase, Group, PrismaClient, User } from '@prisma/client';

@Injectable()
export class GroupService {
  constructor(
    @Inject(forwardRef(() => UserService))
    private userService: UserService,
    @Inject(forwardRef(() => EventService))
    private eventService: EventService,
    private prisma: PrismaClient,
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
    const group = await this.getGroupFromFriendlyId(joinId);
    const hostUser = await this.prisma.user.findFirstOrThrow({
      where: { id: group.hostId! },
    });

    // check restriction
    if (hostUser.restrictedById !== user.restrictedById) return;

    // remove user from old group
    await this.leaveGroup(user)
    // call fix on old group
    this.fixOrDeleteGroup(oldGroup)
    // add user to group
    // this.prisma.group.update({})
    return oldGroup;
  }

  /** Moves the user out of their current group into a new group.
   * Returns the old group if it still exists, or null. */
  // create new group
  // move user to new group
  // remove from old
  // fix old
  // fix new
  // This function is not done
  async leaveGroup(user: User): Promise<Group | undefined> {
    if (!user.groupId) return;
    const userOldGroup = await this.getGroupForUser(user);
    const oldGroup = await this.createFromEvent(
      await this.prisma.eventBase.findFirstOrThrow({
        where: { id: userOldGroup.curEventId },
      }),
    );
    return oldGroup;
  }
  // If no host, and empty, delete
  // If no host, and not empty, replace host
  // If host, and empty, delete
  async fixOrDeleteGroup(group: Group) {
    throw new Error('Method not implemented.');
  }
}

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
    const group: Group = this.prisma.group.create({
      data: {
        currentEvent: event,
        friendlyId: '',
        host: null,
      },
    });

    group.friendlyId = group.id.substring(9, 13);

    // If there is an oldGroup then create a new oldGroup that is processed based on whether the user is the host.
    const oldGroupNew = oldGroup
      ? await this.checkGroupSizeForRemoval(
          oldGroup,
          oldGroup.host.id === host.id,
        )
      : undefined;

    await this.groupsRepository.persistAndFlush(group);
    if (oldGroupNew) {
      oldGroupNew.members.remove(host);
      await this.groupsRepository.persistAndFlush(oldGroupNew);
    }
    group.host = Reference.create(host);
    await this.groupsRepository.persistAndFlush(group);
    host.group = Reference.create(group);
    await this.groupsRepository.persistAndFlush(group);

    return [oldGroupNew, group];
  }

  async saveGroup(group: Group) {
    await this.groupsRepository.persistAndFlush(group);
  }

  /** Get group of the user */
  async getGroupForUser(user: User): Promise<Group> {
    return await user.group.load();
  }

  /** Get group from by the friendlyId.
   * Throws an error if the id does not correspond to a group. */
  async getGroupFromFriendlyId(id: string): Promise<Group> {
    return await this.groupsRepository.findOneOrFail({ friendlyId: id });
  }

  /** Adds user to an existing group, given by the group's id.
   * Returns the old group if it still exists, or null. */
  async joinGroup(user: User, joinId: string): Promise<Group | undefined> {
    const group = await this.getGroupFromFriendlyId(joinId);
    const oldGroup = await user.group.load();

    if (oldGroup.friendlyId === joinId) return;

    const host = await group.host.load();

    if (host.restrictedBy?.id !== user.restrictedBy?.id) return;

    const ret = await this.checkGroupSizeForRemoval(
      oldGroup,
      oldGroup.host.id === user.id,
    );

    group.members.add(user);
    user.group = Reference.create(group);

    await this.groupsRepository.persistAndFlush(group);
    return ret;
  }

  /** Moves the user out of their current group into a new group.
   * Returns the old group if it still exists, or null. */
  async leaveGroup(user: User): Promise<Group | undefined> {
    if (!user.group) return;
    const userOldGroup = await this.getGroupForUser(user);
    const [oldGroup] = await this.createFromEvent(
      await userOldGroup.currentEvent.load(),
      user,
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

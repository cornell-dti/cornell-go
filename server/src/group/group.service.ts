import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { EventBase } from '../model/event-base.entity';
import { Group } from '../model/group.entity';
import { User } from '../model/user.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { UserService } from '../user/user.service';
import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { v4 } from 'uuid';
import { elementAt, NotFoundError } from 'rxjs';
import { Reference, Unique } from '@mikro-orm/core';

@Injectable()
export class GroupService {
  constructor(
    @Inject(forwardRef(() => UserService))
    private userService: UserService,
    @InjectRepository(Group)
    private groupsRepository: EntityRepository<Group>,
  ) {}

  /** Creates a group from an event and removes from an old group (does delete empty groups) */
  async createFromEvent(
    event: EventBase,
    host: User,
    isNew = false,
  ): Promise<[Group | undefined, Group]> {
    const oldGroup = isNew ? null : await host.group.load();

    const group: Group = this.groupsRepository.create({
      id: v4(),
      currentEvent: event,
      members: [host],
      friendlyId: '',
      host: null,
    });

    group.friendlyId = group.id.substring(9, 13);

    oldGroup?.members.remove(host);
    host.group = Reference.create(group);

    const oldGroupNew = oldGroup
      ? await this.checkGroupSize(oldGroup)
      : undefined;

    group.host = Reference.create(host);

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

  /* If the user is the only member, deletes the group. */
  async checkGroupSize(group: Group): Promise<Group | undefined> {
    if (group.members.length === 0) {
      group.host = null!;
      await this.groupsRepository.persistAndFlush(group);
      await this.groupsRepository.removeAndFlush(group);
      return undefined;
    } else {
      group.host = Reference.create((await group.members.loadItems())[0]);
      await this.groupsRepository.persistAndFlush(group);
    }
    return group;
  }

  /** Adds user to an existing group, given by the group's id.
   * Returns the old group if it still exists, or null. */
  async joinGroup(user: User, joinId: string): Promise<Group | undefined> {
    const group = await this.getGroupFromFriendlyId(joinId);
    const oldGroup = await user.group!.load();

    group.members.add(user);
    user.group?.set(group);

    await this.groupsRepository.persistAndFlush(group);

    return await this.checkGroupSize(oldGroup);
  }

  /** Moves the user out of their current group into a new group.
   * Returns the old group if it still exists, or null. */
  async leaveGroup(user: User): Promise<Group | undefined> {
    const userOldGroup = await this.getGroupForUser(user);
    const [oldGroup] = await this.createFromEvent(
      await userOldGroup.currentEvent.load(),
      user,
    );
    return oldGroup;
  }
}

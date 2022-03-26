import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { EventBase } from '../model/event-base.entity';
import { Group } from '../model/group.entity';
import { User } from '../model/user.entity';
import { GroupMember } from '../model/group-member.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { UserService } from '../user/user.service';
import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { v4 } from 'uuid';
import { elementAt, NotFoundError } from 'rxjs';
import { Reference } from '@mikro-orm/core';

@Injectable()
export class GroupService {
  constructor(
    @Inject(forwardRef(() => UserService))
    private userService: UserService,
    @InjectRepository(Group)
    private groupsRepository: EntityRepository<Group>,
    @InjectRepository(GroupMember)
    private groupMembersRepository: EntityRepository<GroupMember>,
  ) {}

  /** Creates a group from an event */
  async createFromEvent(event: EventBase, host: User) {
    let group: Group = this.groupsRepository.create({
      id: v4(),
      currentEvent: event,
      members: [],
      friendlyId: '',
    });

    group.friendlyId = group.id.substring(9, 13);

    await this.groupsRepository.persistAndFlush(group);

    let groupMember: GroupMember = this.groupMembersRepository.create({
      isHost: true,
      user: host,
      group,
    });

    group.members.set([groupMember]);
    host.groupMember = Reference.create(groupMember);
    groupMember.user.set(host);

    await this.groupsRepository.persistAndFlush(group);
    return group;
  }

  async saveGroup(group: Group) {
    await this.groupsRepository.persistAndFlush(group);
  }

  /** Get group of the user */
  async getGroupForUser(user: User): Promise<Group> {
    const groupMember = await user.groupMember!.load();
    return await groupMember!.group.load();
  }

  /** Get group from by the friendlyId.
   * Throws a NotFoundError if the id does not correspond to a group. */
  async getGroupFromFriendlyId(id: string): Promise<Group> {
    return await this.groupsRepository.findOneOrFail({ friendlyId: id });
  }

  /** Helper function that removes a user from their current group.
   * If the user is the only member, deletes the group. */
  async removeUserFromGroup(user: User): Promise<Group | null> {
    const oldGroup = await this.getGroupForUser(user);
    oldGroup.members.remove(await user.groupMember!.load());
    if (oldGroup.members.length == 0) {
      this.groupsRepository.removeAndFlush(oldGroup);
      return null;
    }
    return oldGroup;
  }

  /** Adds user to an existing group, given by the group's id.
   * Returns the old group if it still exists, or null. */
  async joinGroup(user: User, joinId: string): Promise<Group | null> {
    const oldGroup = await this.removeUserFromGroup(user);
    const group = await this.getGroupFromFriendlyId(joinId);
    let groupMember: GroupMember = this.groupMembersRepository.create({
      isHost: false,
      user: user,
      group: group,
    });

    group.members.set([groupMember]);
    user.groupMember?.set(groupMember);
    groupMember.user.set(user);

    await this.groupsRepository.persistAndFlush(group);
    return oldGroup;
  }

  /** Moves the user out of their current group into a new group.
   * Returns the old group if it still exists, or null. */
  async leaveGroup(user: User): Promise<Group | null> {
    const userOldGroup = await this.getGroupForUser(user);
    const updatedOldGroup = await this.removeUserFromGroup(user);
    await this.createFromEvent(await userOldGroup.currentEvent.load(), user);
    return updatedOldGroup;
  }
}

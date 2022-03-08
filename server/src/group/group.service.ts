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
  ) { }

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

  /** Get group of the user */
  async getGroupForUser(user: User): Promise<Group> {
    const groupMember = await user.groupMember!.load();
    return groupMember!.group.load();
  }

  /** Get group from the id. 
   * Throws a NotFoundError if the id does not correspond to a group. */
  async getGroupFromID(id: string): Promise<Group> {
    const group = await this.groupsRepository.findOne({ friendlyId: id })
    if (group == null)
      throw NotFoundError
    return group
  }

  /** Helper function that removes a user from their current group.
   * If the user is the only member, deletes the group. */
  async removeUserFromGroup(user: User) {
    const oldGroup = await this.getGroupForUser(user);
    oldGroup.members.remove(await user.groupMember!.load());
    if (oldGroup.members.length == 0)
      this.groupsRepository.removeAndFlush(oldGroup);
  }

  /** Adds user to an existing group, given by the group's id. */
  async joinGroup(user: User, joinId: string) {
    this.removeUserFromGroup(user);
    const group = await this.getGroupFromID(joinId);
    let groupMember: GroupMember = this.groupMembersRepository.create({
      isHost: false,
      user: user,
      group: group,
    });

    group.members.set([groupMember]);
    user.groupMember?.set(groupMember);
    groupMember.user.set(user);

    await this.groupsRepository.persistAndFlush(group);
  }

  /** Moves the user out of their current group into a new group */
  async leaveGroup(user: User) {
    const oldGroup = await this.getGroupForUser(user);
    const newGroupId = (await this.createFromEvent((await oldGroup.currentEvent.load()), user)).friendlyId;
    this.joinGroup(user, newGroupId)
  }
}

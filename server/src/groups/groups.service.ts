import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EventBase } from '../model/event-base.entity';
import { Group } from '../model/group.entity';
import { Repository } from 'typeorm';
import { User } from '../model/user.entity';
import { GroupMember } from '../model/group-member.entity';

@Injectable()
export class GroupsService {
  constructor(
    @InjectRepository(Group)
    private groupsRepository: Repository<Group>,
    @InjectRepository(GroupMember)
    private groupMembersRepository: Repository<GroupMember>,
  ) {}

  /** Creates a group from an event */
  async createFromEvent(event: EventBase, host: User) {
    let group: Group = Object.assign(new Group(), {
      currentEvent: event,
      members: [],
    });

    await this.groupsRepository.save(group);

    let groupMember: GroupMember = Object.assign(new GroupMember(), {
      isHost: true,
      user: host,
      group,
    });

    group.members = [groupMember];
    host.groupMember = groupMember;

    await this.groupMembersRepository.save(groupMember);
    return group;
  }
}

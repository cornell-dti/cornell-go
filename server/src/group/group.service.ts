import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { EventBase } from '../model/event-base.entity';
import { Group } from '../model/group.entity';
import { User } from '../model/user.entity';
import { GroupMember } from '../model/group-member.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { UserService } from '../user/user.service';
import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';

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
      currentEvent: event,
      members: [],
      friendlyId: 'ABCDEF',
    });

    await this.groupsRepository.persistAndFlush(group);

    let groupMember: GroupMember = this.groupMembersRepository.create({
      isHost: true,
      user: host,
      group,
    });

    group.members.set([groupMember]);
    host.groupMember?.set(groupMember);
    groupMember.user.set(host);

    await this.groupsRepository.persistAndFlush(group);
    return group;
  }
}

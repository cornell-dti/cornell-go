import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { InjectEntityManager, InjectRepository } from '@nestjs/typeorm';
import { EventBase } from '../model/event-base.entity';
import { Group } from '../model/group.entity';
import { EntityManager, Repository } from 'typeorm';
import { User } from '../model/user.entity';
import { GroupMember } from '../model/group-member.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { UserService } from '../user/user.service';

@Injectable()
export class GroupService {
  constructor(
    @Inject(forwardRef(() => UserService))
    private userService: UserService,
    @InjectRepository(Group)
    private groupsRepository: Repository<Group>,
    @InjectRepository(GroupMember)
    private groupMembersRepository: Repository<GroupMember>,
    @InjectEntityManager()
    private entityManager: EntityManager,
  ) {}

  /** Creates a group from an event */
  async createFromEvent(event: EventBase, host: User) {
    let group: Group = this.groupsRepository.create({
      currentEvent: event,
      members: [],
      friendlyId: 'ABCDEF',
    });

    await this.entityManager.save(group);

    let groupMember: GroupMember = this.groupMembersRepository.create({
      isHost: true,
      user: host,
      group,
    });

    group.members = [groupMember];
    host.groupMember = groupMember;
    groupMember.user = host;

    await this.entityManager.save([groupMember, group, host]);
    return group;
  }

  /** */
  async requestGroupData(authToken: string) {
    return;
  }
}

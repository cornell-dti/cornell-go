import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { EventBase, EventRewardType } from '../model/event-base.entity';
import { GroupMember } from '../model/group-member.entity';
import { Group } from '../model/group.entity';
import { AuthType, User } from '../model/user.entity';
import { GroupsService } from './groups.service';

describe('GroupsService', () => {
  let service: GroupsService;
  let user: User;
  let event: EventBase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GroupsService,
        { useValue: null, provide: getRepositoryToken(Group) },
        { useValue: null, provide: getRepositoryToken(GroupMember) },
      ],
    }).compile();

    service = module.get<GroupsService>(GroupsService);

    user = {
      id: '',
      score: 0,
      participatingEvents: [],
      logEntries: [],
      groupMember: null,
      username: 'Username',
      email: 'Email',
      authToken: 'Token',
      authType: AuthType.DEVICE,
    };

    event = {
      id: '',
      minMembers: 0,
      skippingEnabled: false,
      isDefault: true,
      hasStarChallenge: false,
      name: 'myEvent',
      description: 'desc',
      rewardType: EventRewardType.NO_REWARDS,
      time: new Date(),
      topCount: 0,
      rewards: [],
      challenges: [],
    };
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

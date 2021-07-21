import { Test, TestingModule } from '@nestjs/testing';
import { getEntityManagerToken, TypeOrmModule } from '@nestjs/typeorm';
import { EntityManager } from 'typeorm';
import { EventBase, EventRewardType } from '../model/event-base.entity';
import { GroupMember } from '../model/group-member.entity';
import { Group } from '../model/group.entity';
import { AuthType, User } from '../model/user.entity';
import { GroupsService } from './groups.service';

describe('GroupsService', () => {
  let service: GroupsService;
  let entityManager: EntityManager;
  let user: User;
  let event: EventBase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [TypeOrmModule.forFeature([Group, GroupMember], 'test')],
      providers: [GroupsService],
    }).compile();

    service = module.get<GroupsService>(GroupsService);
    entityManager = module.get<EntityManager>(getEntityManagerToken());

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

    entityManager.save(event);
    entityManager.save(user);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create a group correctly', async () => {
    let group = await service.createFromEvent(event, user);

    let updatedUser = await entityManager.findOne<User>(user.id);

    expect(updatedUser?.id).toEqual(user.id); // Make sure that this is the correct user
    expect(updatedUser?.groupMember).toEqual(group.members[0]); // Make sure that the member is correct
  });
});

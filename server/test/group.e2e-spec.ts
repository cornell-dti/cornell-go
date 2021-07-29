import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { Connection, createConnection, EntityManager } from 'typeorm';
import { AuthType, User } from '../src/model/user.entity';
import { getEntityManagerToken } from '@nestjs/typeorm';
import { EventBase, EventRewardType } from '../src/model/event-base.entity';
import { GroupService } from '../src/group/group.service';
import { Challenge } from '../src/model/challenge.entity';
import { EventProgress } from '../src/model/event-progress.entity';
import { EventReward } from '../src/model/event-reward.entity';
import { GroupMember } from '../src/model/group-member.entity';
import { PrevChallenge } from '../src/model/prev-challenge.entity';
import { SessionLogEntry } from '../src/model/session-log-entry.entity';
import { Admin } from '../src/model/admin.entity';
import { Group } from '../src/model/group.entity';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  /*
  it('/ (GET)', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });
  */
});

describe('Group integration tests', () => {
  let app: INestApplication;
  let entityManager: EntityManager;
  let user: User;
  let event: EventBase;
  let groupService: GroupService;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(Connection)
      .useValue(
        await createConnection({
          type: 'postgres',
          host: 'localhost',
          username: 'postgres',
          password: 'test',
          database: 'postgres',
          schema: 'test',
          logNotifications: true,
          entities: [
            Admin,
            Challenge,
            EventBase,
            EventProgress,
            EventReward,
            GroupMember,
            Group,
            PrevChallenge,
            SessionLogEntry,
            User,
          ],
          synchronize: true,
          dropSchema: true,
        }),
      )
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    entityManager = moduleFixture.get<EntityManager>(getEntityManagerToken());
    groupService = moduleFixture.get<GroupService>(GroupService);

    user = entityManager.create(User, {
      score: 0,
      participatingEvent: [],
      logEntries: [],
      groupMember: null,
      username: 'Username',
      email: 'Email',
      authToken: 'Token',
      authType: AuthType.DEVICE,
    });

    event = entityManager.create(EventBase, {
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
    });

    await entityManager.save([user, event]);
  });

  it('should create a group correctly', async () => {
    let group = await groupService.createFromEvent(event, user);

    let updatedUser = await entityManager.findOne(User, {
      where: { id: user.id },
      relations: ['groupMember'],
    });
    expect(updatedUser).toBeDefined(); // Make sure that this is the correct user
    expect(updatedUser?.groupMember?.id).toEqual(group.members[0]?.id); // Make sure that the member is correct
  });
});

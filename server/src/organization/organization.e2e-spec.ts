import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { OrganizationService } from './organization.service';
import { AppModule } from '../app.module';
import { ChallengeService } from '../challenge/challenge.service';
import { EventService } from '../event/event.service';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { UserService } from '../user/user.service';
import {
  AuthType,
  Challenge,
  EnrollmentType,
  EventBase,
  Group,
  Organization,
  OrganizationSpecialUsage,
  User,
} from '@prisma/client';
import { GroupService } from '../group/group.service';
import { ClientService } from '../client/client.service';
import { UserGateway } from '../user/user.gateway';
import { ChallengeGateway } from '../challenge/challenge.gateway';
import { OrganizationGateway } from './organization.gateway';
import { GroupGateway } from '../group/group.gateway';
import { EventGateway } from '../event/event.gateway';
import { UpdateUserDataDto } from '../user/user.dto';

describe('OrganizationModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  let chalGateway: ChallengeGateway;
  let evGateway: EventGateway;
  let orgGateway: OrganizationGateway;
  let userGateway: UserGateway;
  let groupGateway: GroupGateway;

  let challengeService: ChallengeService;
  let eventService: EventService;
  let orgService: OrganizationService;
  let userService: UserService;
  let groupService: GroupService;
  let clientService: ClientService;
  let abilityFactory: CaslAbilityFactory;

  let managerUser: User;
  let basicUser: User;

  let managerGroup: Group;
  let basicGroup: Group;

  let fullAbility: AppAbility;
  let managerAbility: AppAbility;
  let basicAbility: AppAbility;

  let defaultOrg: Organization;
  let defaultEv: EventBase;
  let defaultChal: Challenge;

  let exOrg: Organization;
  let exEv: EventBase;
  let exChal: Challenge;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();

    abilityFactory = moduleRef.get<CaslAbilityFactory>(CaslAbilityFactory);
    challengeService = moduleRef.get<ChallengeService>(ChallengeService);
    eventService = moduleRef.get<EventService>(EventService);
    orgService = moduleRef.get<OrganizationService>(OrganizationService);
    userService = moduleRef.get<UserService>(UserService);
    clientService = moduleRef.get<ClientService>(ClientService);
    groupService = moduleRef.get<GroupService>(GroupService);

    chalGateway = moduleRef.get<ChallengeGateway>(ChallengeGateway);
    evGateway = moduleRef.get<EventGateway>(EventGateway);
    orgGateway = moduleRef.get<OrganizationGateway>(OrganizationGateway);
    userGateway = moduleRef.get<UserGateway>(UserGateway);
    groupGateway = moduleRef.get<GroupGateway>(GroupGateway);

    fullAbility = abilityFactory.createFull();

    exOrg = (await orgService.upsertOrganizationFromDto(fullAbility, {
      id: '',
    }))!;

    exEv = (await eventService.upsertEventFromDto(fullAbility, {
      id: '',
      initialOrganizationId: exOrg.id,
    }))!;

    exChal = (await challengeService.upsertChallengeFromDto(fullAbility, {
      id: '',
      linkedEventId: exEv.id,
    }))!;

    defaultOrg = await orgService.getDefaultOrganization(
      OrganizationSpecialUsage.CORNELL_LOGIN,
    );

    defaultEv = (await eventService.getEventById(
      (
        await eventService.getCurrentEventTrackerForUser(basicUser)
      ).eventId,
    ))!;

    defaultChal = (await challengeService.getChallengeById(
      (
        await eventService.getCurrentEventTrackerForUser(basicUser)
      ).curChallengeId,
    ))!;

    managerUser = await userService.register(
      'manager@cornell.edu',
      'manager',
      '2024',
      0,
      0,
      AuthType.DEVICE,
      'a',
      EnrollmentType.UNDERGRADUATE,
    );

    basicUser = await userService.register(
      'basic@cornell.edu',
      'basic',
      '2024',
      0,
      0,
      AuthType.DEVICE,
      'b',
      EnrollmentType.UNDERGRADUATE,
    );

    managerGroup = await groupService.getGroupForUser(managerUser);
    basicGroup = await groupService.getGroupForUser(basicUser);
    await orgService.addManager(fullAbility, 'manager@cornell.edu', exOrg.id);

    managerAbility = abilityFactory.createForUser(managerUser);
    basicAbility = abilityFactory.createForUser(basicUser);

    clientService.getAffectedUsers = async (target: string) => [
      managerUser,
      basicUser,
    ];

    await app.init();
  });

  it('should successfully find OrganizationService', async () => {
    const orgService = moduleRef.get<OrganizationService>(OrganizationService);

    expect(orgService).toBeDefined();
  });

  describe('Basic and manager user abilities', async () => {
    it('Should be able to read own data', async () => {
      await userGateway.requestUserData(basicAbility, basicUser, {});
      const [users, ev, dto] = spyOn(clientService, 'sendEvent').mostRecentCall
        .args as [string[], string, UpdateUserDataDto];

      expect(users).toContain(basicUser.id);
      expect(users).not.toContain(managerUser.id);
      expect(ev).toEqual('updateUserData');
      expect(dto.user).toEqual(
        expect.objectContaining({
          email: basicUser.email,
          groupId: basicUser.groupId,
          id: basicUser.id,
          score: basicUser.score,
          enrollmentType: basicUser.enrollmentType,
          username: basicUser.username,
          year: basicUser.year,
        }),
      );
    });

    it('Should be able to modify own username', async () => {
      await userGateway.updateUserData(basicAbility, basicUser, {
        user: { id: basicUser.id, username: 'myNewUsername' },
        deleted: false,
      });

      const [users, ev, dto] = spyOn(clientService, 'sendEvent').mostRecentCall
        .args as [string[], string, UpdateUserDataDto];

      expect(ev).toEqual('updateUserData');
      expect(dto.user.username).toEqual('myNewUsername');
    });

    it('Should be able to read from own org', async () => {
      await evGateway.requestEventData(basicAbility, basicUser, {
        events: [],
      });
    });

    it('Should not be able to read other group', async () => {});

    it('Should not be able to read other user', async () => {});

    it('Should not be able to see other org', async () => {});

    it('Should not be able to modify anything in nonmanaged org', async () => {});

    it('Should not be able to add managers', async () => {});
  });

  describe('Manager user abilities', () => {
    it('Should be able to add managers to managed org', async () => {});

    it('Should be able to modify managed org', async () => {});
  });

  afterAll(async () => {
    await app.close();
  });
});

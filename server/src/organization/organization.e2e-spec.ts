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

describe('OrganizationModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  let challengeService: ChallengeService;
  let eventService: EventService;
  let orgService: OrganizationService;
  let userService: UserService;
  let groupService: GroupService;
  let abilityFactory: CaslAbilityFactory;

  let managerUser: User;
  let basicUser: User;

  let managerGroup: Group;
  let basicGroup: Group;

  let fullAbility: AppAbility;
  let managerAbility: AppAbility;
  let basicAbility: AppAbility;

  let defaultOrg: Organization;
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
    groupService = moduleRef.get<GroupService>(GroupService);

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

    await app.init();
  });

  it('should successfully find OrganizationService', async () => {
    const orgService = moduleRef.get<OrganizationService>(OrganizationService);

    expect(orgService).toBeDefined();
  });

  describe('Basic and manager user abilities', async () => {
    it('Should be able to read own data', async () => {});

    it('Should be able to modify hosted group', async () => {});

    it('Should be able to modify own username', async () => {});

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

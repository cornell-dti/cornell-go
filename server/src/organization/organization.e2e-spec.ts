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
import { UpdateEventDataDto } from '../event/event.dto';
import { UpdateChallengeDataDto } from '../challenge/challenge.dto';

type DtoLastCall<T> = [string[], string, T];

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

  let sendEventMock: jest.SpyInstance<Promise<void>, [string[], string, any]>;

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

    sendEventMock = jest.spyOn(clientService, 'sendEvent').mockImplementation();

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
      location: 'ARTS_QUAD',
    }))!;

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

  afterEach(() => {
    sendEventMock.mockClear();
  });

  it('should successfully find OrganizationService', async () => {
    const orgService = moduleRef.get<OrganizationService>(OrganizationService);

    expect(orgService).toBeDefined();
  });

  describe('Basic and manager user abilities', () => {
    it('Should be able to read own data', async () => {
      await userGateway.requestUserData(basicAbility, basicUser, {});

      const [users, ev, dto]: DtoLastCall<UpdateUserDataDto> =
        sendEventMock.mock.lastCall;

      expect(ev).toEqual('updateUserData');
      expect(users).toContain(basicUser.id);
      expect(users).not.toContain(managerUser.id);

      expect(dto.user.id).toEqual(basicUser.id);
      expect(dto.user.email).toEqual(basicUser.email);
      expect(dto.user.score).toEqual(basicUser.score);
      expect(dto.user.enrollmentType).toEqual(basicUser.enrollmentType);
      expect(dto.user.username).toEqual(basicUser.username);
      expect(dto.user.year).toEqual(basicUser.year);
    });

    it('Should be able to modify own username', async () => {
      await userGateway.updateUserData(basicAbility, basicUser, {
        user: { id: basicUser.id, username: 'myNewUsername' },
        deleted: false,
      });

      const [users, ev, dto]: DtoLastCall<UpdateUserDataDto> =
        sendEventMock.mock.lastCall;

      expect(ev).toEqual('updateUserData');
      expect(dto.user.username).toEqual('myNewUsername');
    });

    it('Should not be able to modify ban status', async () => {
      await userGateway.updateUserData(basicAbility, basicUser, {
        user: { id: basicUser.id, isBanned: true },
        deleted: false,
      });

      const [users, ev, dto]: DtoLastCall<UpdateUserDataDto> =
        sendEventMock.mock.lastCall;

      expect(ev).toEqual('updateUserData');
      expect(dto.user.isBanned).toEqual(false);
    });

    it('Should be able to read from own org', async () => {
      await evGateway.requestEventData(basicAbility, basicUser, {
        events: [defaultEv.id],
      });

      let [users, ev, dto] = sendEventMock.mock.lastCall as [
        string[],
        string,
        UpdateEventDataDto,
      ];

      expect(ev).toEqual('updateEventData');
      expect(dto.event.id).toEqual(defaultEv.id);
      expect(dto.event.name).toEqual(defaultEv.name);

      await chalGateway.requestChallengeData(basicAbility, basicUser, {
        challenges: [defaultChal.id],
      });

      let [users2, ev2, dto2] = sendEventMock.mock.lastCall as [
        string[],
        string,
        UpdateChallengeDataDto,
      ];

      expect(ev2).toEqual('updateChallengeData');
      expect(dto2.challenge.id).toEqual(defaultChal.id);
      expect(dto2.challenge.name).toEqual(defaultChal.name);
      console.log('Should be able to read from own org finalized');
    });

    it('Should not be able to read other user', async () => {
      await userGateway.requestAllUserData(basicAbility, basicUser, {});

      expect(
        sendEventMock.mock.calls.every(call => {
          const [users, ev, dto]: DtoLastCall<UpdateUserDataDto> = call;

          // Check only the call with updateUserData directed at basicUser not any other one
          if (users.includes(basicUser.id) && ev === 'updateUserData')
            return basicUser.id === dto.user.id;
          else return true;
        }),
      ).toBeTruthy();
    });

    it('Should not be able to see other org', async () => {
      await evGateway.requestEventData(basicAbility, basicUser, {
        events: [exEv.id],
      });

      expect(
        sendEventMock.mock.calls.every(call => {
          const [users, ev, dto]: DtoLastCall<UpdateEventDataDto> = call;

          if (users.includes(basicUser.id) && ev === 'updateEventData')
            return exEv.id !== dto.event.id;
          else return true;
        }),
      ).toBeTruthy();

      await chalGateway.requestChallengeData(basicAbility, basicUser, {
        challenges: [exChal.id],
      });

      expect(
        sendEventMock.mock.calls.every(call => {
          const [users, ev, dto]: DtoLastCall<UpdateChallengeDataDto> = call;

          if (users.includes(basicUser.id) && ev === 'updateChallengeData')
            return exChal.id !== dto.challenge.id;
          else return true;
        }),
      ).toBeTruthy();
    });
  });

  describe('Manager user abilities', () => {
    it('Should be able to add managers to managed org', async () => {
      const addState = await orgService.addManager(
        managerAbility,
        'manager@cornell.edu',
        exOrg.id,
      );

      expect(addState).toBeTruthy();
    });

    it('Should not be able to add managers to another org', async () => {
      const addState = await orgService.addManager(
        managerAbility,
        'manager@cornell.edu',
        defaultOrg.id,
      );

      expect(addState).toBeFalsy();
    });

    it('Should be able to modify managed org', async () => {
      const newEv = await eventService.upsertEventFromDto(managerAbility, {
        id: exEv.id,
        name: 'New name',
      });

      expect(newEv?.name).toEqual('New name');

      const newChal = await challengeService.upsertChallengeFromDto(
        managerAbility,
        {
          id: exChal.id,
          name: 'New Name',
        },
      );

      expect(newChal?.name).toEqual('New Name');
    });

    it('Should not be able to modify other org', async () => {
      const newEv = await eventService.upsertEventFromDto(managerAbility, {
        id: defaultEv.id,
        name: 'New name',
      });

      expect(newEv?.name).not.toEqual('New name');

      const newChal = await challengeService.upsertChallengeFromDto(
        managerAbility,
        {
          id: defaultChal.id,
          name: 'New Name',
        },
      );

      expect(newChal?.name).not.toEqual('New Name');
    });
  });

  afterAll(async () => {
    await userService.deleteUser(fullAbility, basicUser);
    await userService.deleteUser(fullAbility, managerUser);
    await challengeService.removeChallenge(fullAbility, exChal.id);
    await eventService.removeEvent(fullAbility, exEv.id);
    await orgService.removeOrganization(fullAbility, exOrg.id);
    await app.close();
  });
});

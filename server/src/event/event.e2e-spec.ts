import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { EventService } from './event.service';
import { AppModule } from '../app.module';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { ChallengeGateway } from '../challenge/challenge.gateway';
import { EventGateway } from './event.gateway';
import { UserGateway } from '../user/user.gateway';
import { ChallengeService } from '../challenge/challenge.service';
import { UserService } from '../user/user.service';
import { ClientService } from '../client/client.service';
import {
  AuthType,
  Challenge,
  EnrollmentType,
  EventBase,
  Organization,
  OrganizationSpecialUsage,
  User,
} from '@prisma/client';
import { OrganizationService } from '../organization/organization.service';
import { GroupGateway } from '../group/group.gateway';

describe('EventModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  let fullAbility: AppAbility;
  let sendEventMock: jest.SpyInstance<Promise<void>, [string[], string, any]>;

  let chalGateway: ChallengeGateway;
  let evGateway: EventGateway;
  let userGateway: UserGateway;
  let groupGateway: GroupGateway;

  let orgService: OrganizationService;
  let challengeService: ChallengeService;
  let eventService: EventService;
  let userService: UserService;
  let clientService: ClientService;
  let abilityFactory: CaslAbilityFactory;

  let playerOrg: Organization;
  let exPlayer: User;
  let exPlayerAbility: AppAbility;

  let exJourney1: EventBase;
  let exJourney2: EventBase;
  let exChallenge1: EventBase;

  let journey1Chal: Challenge;
  let journey2Chal: Challenge;

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

    sendEventMock = jest.spyOn(clientService, 'sendEvent').mockImplementation();

    chalGateway = moduleRef.get<ChallengeGateway>(ChallengeGateway);
    evGateway = moduleRef.get<EventGateway>(EventGateway);
    userGateway = moduleRef.get<UserGateway>(UserGateway);
    groupGateway = moduleRef.get<GroupGateway>(GroupGateway);

    fullAbility = abilityFactory.createFull();

    exPlayer = await userService.register(
      'player1@cornell.edu',
      'player1',
      '2024',
      0,
      0,
      AuthType.NONE,
      'player1auth',
      EnrollmentType.UNDERGRADUATE,
    );

    exPlayerAbility = await abilityFactory.createForUser(exPlayer);

    playerOrg = await orgService.getDefaultOrganization(
      OrganizationSpecialUsage.CORNELL_LOGIN,
    );

    clientService.getAffectedUsers = async (target: string) => [exPlayer];

    exJourney1 = await orgService.makeDefaultEvent();
    exJourney2 = await orgService.makeDefaultEvent();
    exChallenge1 = await orgService.makeDefaultEvent();

    journey1Chal = await orgService.makeDefaultChallenge();
    journey2Chal = await orgService.makeDefaultChallenge();

    await challengeService.addChallengeToEvent(journey1Chal, exJourney1);
    await challengeService.addChallengeToEvent(journey2Chal, exJourney2);

    await app.init();
  });

  it('should successfully find EventService', async () => {
    const evService = moduleRef.get<EventService>(EventService);

    expect(evService).toBeDefined();
  });

  describe('Playthrough testing', () => {
    it('Should successfully complete a playthrough', async () => {
      await groupGateway.setCurrentEvent(exPlayer, { eventId: exJourney1.id });
      const tracker1 = await eventService.getCurrentEventTrackerForUser(
        exPlayer,
      );
      expect(tracker1.eventId).toEqual(exJourney1.id);
      expect(tracker1.score).toEqual(0);
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker1.curChallengeId,
        ),
      ).toBeTruthy();
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker1.curChallengeId,
        ),
      ).toBeFalsy();

      const tracker2 = await eventService.getCurrentEventTrackerForUser(
        exPlayer,
      );
      expect(tracker2.score).toEqual(1);
      expect(tracker2.curChallengeId).toEqual(journey1Chal.id);

      await groupGateway.setCurrentEvent(exPlayer, { eventId: exJourney2.id });
      const tracker3 = await eventService.getCurrentEventTrackerForUser(
        exPlayer,
      );
      expect(tracker3.score).toEqual(0);
      expect(tracker3.eventId).toEqual(exJourney2.id);
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker2.curChallengeId,
        ),
      ).toBeFalsy();
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker3.curChallengeId,
        ),
      ).toBeTruthy();
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker3.curChallengeId,
        ),
      ).toBeFalsy();

      const tracker4 = await eventService.getCurrentEventTrackerForUser(
        exPlayer,
      );
      expect(tracker4.score).toEqual(1);
      expect(tracker4.curChallengeId).toEqual(journey2Chal.id);
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker4.curChallengeId,
        ),
      ).toBeTruthy();
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker4.curChallengeId,
        ),
      ).toBeFalsy();

      const tracker5 = await eventService.getCurrentEventTrackerForUser(
        exPlayer,
      );
      expect(tracker5.score).toEqual(1);
      expect(tracker5.curChallengeId).toEqual(journey2Chal.id);

      await groupGateway.setCurrentEvent(exPlayer, {
        eventId: exChallenge1.id,
      });

      const tracker6 = await eventService.getCurrentEventTrackerForUser(
        exPlayer,
      );
      expect(tracker6.score).toEqual(0);
      expect(tracker6.eventId).toEqual(exChallenge1.id);
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker6.curChallengeId,
        ),
      ).toBeTruthy();
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker6.curChallengeId,
        ),
      ).toBeFalsy();

      const tracker7 = await eventService.getCurrentEventTrackerForUser(
        exPlayer,
      );
      expect(tracker7.score).toEqual(1);
      expect(tracker7.curChallengeId).toEqual(tracker6.curChallengeId);

      await groupGateway.setCurrentEvent(exPlayer, { eventId: exJourney1.id });

      const tracker8 = await eventService.getCurrentEventTrackerForUser(
        exPlayer,
      );
      expect(tracker8.score).toEqual(1);
      expect(tracker8.eventId).toEqual(exJourney1.id);
      expect(tracker8.curChallengeId).toEqual(journey1Chal.id);
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker8.curChallengeId,
        ),
      ).toBeTruthy();
      expect(
        await challengeService.completeChallenge(
          exPlayer,
          tracker8.curChallengeId,
        ),
      ).toBeFalsy();

      const tracker9 = await eventService.getCurrentEventTrackerForUser(
        exPlayer,
      );
      expect(tracker9.score).toEqual(2);
      expect(tracker9.eventId).toEqual(exJourney1.id);
      expect(tracker9.curChallengeId).toEqual(journey1Chal.id);

      const latestUserData = await userService.byId(exPlayer.id);
      expect(latestUserData?.score).toEqual(5);
    });
  });

  afterAll(async () => {
    await userService.deleteUser(fullAbility, exPlayer);
    await eventService.removeEvent(fullAbility, exJourney1.id);
    await eventService.removeEvent(fullAbility, exJourney2.id);
    await eventService.removeEvent(fullAbility, exChallenge1.id);

    await app.close();
  });
});

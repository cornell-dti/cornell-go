import { Test, TestingModule } from '@nestjs/testing';
import { ChallengeService } from './challenge.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { AuthType } from '@prisma/client';
import { SessionLogService } from '../session-log/session-log.service';
import { EventService } from '../event/event.service';
import { ClientService } from '../client/client.service';
import { GroupService } from '../group/group.service';
import { OrganizationService } from '../organization/organization.service';
import { ClientModule } from '../client/client.module';

describe('ChallengeService', () => {
  let service: ChallengeService;
  let prisma: PrismaService;
  let userService: UserService;
  let sessionLogService: SessionLogService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [ClientModule],
      providers: [
        ChallengeService,
        PrismaService,
        UserService,
        SessionLogService,
        EventService,
        ClientService,
        GroupService,
        OrganizationService,
      ],
    }).compile();

    service = module.get<ChallengeService>(ChallengeService);
    prisma = module.get<PrismaService>(PrismaService);
    userService = module.get<UserService>(UserService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('completeChallenge', () => {
    it('should complete the challenge', async () => {
      const user = await userService.register(
        'test@gmail.com',
        'test',
        'CS',
        '2025',
        0,
        0,
        AuthType.GOOGLE,
        'asdf',
      );
      const score = user.score;
      console.log(score);
      const chalId = (await prisma.challenge.findFirstOrThrow()).id;
      await service.completeChallenge(user, chalId);
      const score2 = (
        await prisma.user.findFirstOrThrow({
          where: {
            id: user.id,
          },
        })
      ).score;
      console.log(score2);
      expect(score + 1).toEqual(score2);
    });
  });
});

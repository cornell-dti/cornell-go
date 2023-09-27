import { Test, TestingModule } from '@nestjs/testing';
import { GroupService } from './group.service';
import { SessionLogService } from '../session-log/session-log.service';
import { EventService } from '../event/event.service';
import { UserService } from '../user/user.service';
import { ClientService } from '../client/client.service';
import { PrismaService } from '../prisma/prisma.service';

describe('GroupService', () => {
  let service: GroupService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GroupService,
        {
          useValue: null,
          provide: SessionLogService,
        },
        {
          useValue: null,
          provide: EventService,
        },
        {
          useValue: null,
          provide: UserService,
        },
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: PrismaService,
        },
      ],
    }).compile();

    service = module.get<GroupService>(GroupService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

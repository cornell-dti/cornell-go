import { Test } from '@nestjs/testing';
import { EventService } from '../event/event.service';
import { GroupService } from '../group/group.service';
import { UserService } from './user.service';
import { PrismaService } from '../prisma/prisma.service';
import { OrganizationService } from '../organization/organization.service';
import { ClientService } from '../client/client.service';
import { SessionLogService } from '../session-log/session-log.service';

describe('UserService', () => {
  let service: UserService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UserService,
        {
          useValue: null,
          provide: EventService,
        },
        {
          useValue: null,
          provide: GroupService,
        },
        {
          useValue: null,
          provide: PrismaService,
        },
        {
          useValue: null,
          provide: OrganizationService,
        },
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: SessionLogService,
        },
      ],
    }).compile();

    service = module.get<UserService>(UserService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

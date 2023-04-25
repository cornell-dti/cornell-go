import { Test } from '@nestjs/testing';
import { EventService } from '../event/event.service';
import { GroupService } from '../group/group.service';
import { UserService } from './user.service';
import { SessionLogModule } from '../session-log/session-log.module';
import { PrismaModule } from '../prisma/prisma.module';
import { OrganizationModule } from '../organization/organization.module';
import { ClientModule } from '../client/client.module';

describe('UserService', () => {
  let service: UserService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      imports: [
        SessionLogModule,
        PrismaModule,
        OrganizationModule,
        ClientModule,
      ],
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
      ],
    }).compile();

    service = module.get<UserService>(UserService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

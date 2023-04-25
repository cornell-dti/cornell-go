import { Test, TestingModule } from '@nestjs/testing';
import { GroupService } from './group.service';
import { SessionLogModule } from '../session-log/session-log.module';
import { EventService } from '../event/event.service';
import { UserModule } from '../user/user.module';
import { ClientModule } from '../client/client.module';
import { PrismaModule } from '../prisma/prisma.module';
import { OrganizationModule } from '../organization/organization.module';

describe('GroupService', () => {
  let service: GroupService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [
        SessionLogModule,
        UserModule,
        ClientModule,
        PrismaModule,
        OrganizationModule,
      ],
      providers: [GroupService, EventService],
    }).compile();

    service = module.get<GroupService>(GroupService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { EventService } from './event.service';
import { EventGateway } from './event.gateway';
import { ClientModule } from '../client/client.module';
import { OrganizationGateway } from '../organization/organization.gateway';
import { OrganizationModule } from '../organization/organization.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

describe('EventService', () => {
  let service: EventService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [ClientModule, OrganizationModule, PrismaModule, AuthModule],
      providers: [EventService, EventGateway],
    }).compile();

    service = module.get<EventService>(EventService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

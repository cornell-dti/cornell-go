import { Test, TestingModule } from '@nestjs/testing';
import { EventGateway } from './event.gateway';
import { ClientModule } from '../client/client.module';
import { EventService } from './event.service';
import { OrganizationModule } from '../organization/organization.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

describe('EventGateway', () => {
  let gateway: EventGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [ClientModule, OrganizationModule, PrismaModule, AuthModule],
      providers: [EventGateway, EventService],
    }).compile();

    gateway = module.get<EventGateway>(EventGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

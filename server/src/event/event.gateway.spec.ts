import { Test, TestingModule } from '@nestjs/testing';
import { EventGateway } from './event.gateway';
import { ClientService } from '../client/client.service';
import { EventService } from './event.service';
import { OrganizationService } from '../organization/organization.service';
import { AuthService } from '../auth/auth.service';

describe('EventGateway', () => {
  let gateway: EventGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EventGateway,
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: EventService,
        },
        {
          useValue: null,
          provide: OrganizationService,
        },
        {
          useValue: null,
          provide: AuthService,
        },
      ],
    }).compile();

    gateway = module.get<EventGateway>(EventGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

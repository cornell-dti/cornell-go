import { Test, TestingModule } from '@nestjs/testing';
import { UserGateway } from './user.gateway';
import { ClientService } from '../client/client.service';
import { UserService } from './user.service';
import { GroupService } from '../group/group.service';
import { EventService } from '../event/event.service';
import { AuthService } from '../auth/auth.service';
import { OrganizationService } from '../organization/organization.service';

describe('UserGateway', () => {
  let gateway: UserGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserGateway,
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: UserService,
        },
        {
          useValue: null,
          provide: GroupService,
        },
        {
          useValue: null,
          provide: EventService,
        },
        {
          useValue: null,
          provide: AuthService,
        },
        {
          useValue: null,
          provide: OrganizationService,
        },
      ],
    }).compile();

    gateway = module.get<UserGateway>(UserGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

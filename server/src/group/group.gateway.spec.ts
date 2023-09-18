import { Test, TestingModule } from '@nestjs/testing';
import { GroupGateway } from './group.gateway';
import { ClientService } from '../client/client.service';
import { GroupService } from './group.service';
import { AuthService } from '../auth/auth.service';

describe('GroupGateway', () => {
  let gateway: GroupGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GroupGateway,
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: GroupService,
        },
        {
          useValue: null,
          provide: AuthService,
        },
      ],
    }).compile();

    gateway = module.get<GroupGateway>(GroupGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

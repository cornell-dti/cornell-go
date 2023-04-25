import { Test, TestingModule } from '@nestjs/testing';
import { GroupGateway } from './group.gateway';
import { ClientModule } from '../client/client.module';
import { GroupService } from './group.service';
import { GroupModule } from './group.module';
import { AuthModule } from '../auth/auth.module';

describe('GroupGateway', () => {
  let gateway: GroupGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [ClientModule, GroupModule, AuthModule],
      providers: [GroupGateway],
    }).compile();

    gateway = module.get<GroupGateway>(GroupGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

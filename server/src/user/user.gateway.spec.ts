import { Test, TestingModule } from '@nestjs/testing';
import { UserGateway } from './user.gateway';
import { ClientModule } from '../client/client.module';
import { UserModule } from './user.module';
import { GroupModule } from '../group/group.module';
import { EventModule } from '../event/event.module';
import { AuthModule } from '../auth/auth.module';

describe('UserGateway', () => {
  let gateway: UserGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [ClientModule, UserModule, GroupModule, EventModule, AuthModule],
      providers: [UserGateway],
    }).compile();

    gateway = module.get<UserGateway>(UserGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

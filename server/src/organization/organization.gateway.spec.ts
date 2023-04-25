import { Test, TestingModule } from '@nestjs/testing';
import { OrganizationGateway } from './organization.gateway';
import { ClientModule } from '../client/client.module';
import { OrganizationModule } from './organization.module';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';

describe('OrganizationGateway', () => {
  let gateway: OrganizationGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [ClientModule, OrganizationModule, UserModule, AuthModule],
      providers: [OrganizationGateway],
    }).compile();

    gateway = module.get<OrganizationGateway>(OrganizationGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

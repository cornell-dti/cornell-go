import { Test, TestingModule } from '@nestjs/testing';
import { AuthGateway } from './auth.gateway';
import { AuthModule } from './auth.module';

describe('AuthGateway', () => {
  let gateway: AuthGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [AuthModule],
      providers: [AuthGateway],
    }).compile();

    gateway = module.get<AuthGateway>(AuthGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

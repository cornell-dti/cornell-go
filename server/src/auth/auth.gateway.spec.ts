import { Test, TestingModule } from '@nestjs/testing';
import { AuthGateway } from './auth.gateway';

describe('AuthGateway', () => {
  let gateway: AuthGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [AuthGateway],
    }).compile();

    gateway = module.get<AuthGateway>(AuthGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

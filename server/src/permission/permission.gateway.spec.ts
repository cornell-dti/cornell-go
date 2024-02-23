import { Test, TestingModule } from '@nestjs/testing';
import { PermissionGateway } from './permission.gateway';

describe('PermissionGateway', () => {
  let gateway: PermissionGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [PermissionGateway],
    }).compile();

    gateway = module.get<PermissionGateway>(PermissionGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

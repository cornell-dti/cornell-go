import { Test, TestingModule } from '@nestjs/testing';
import { OrganizationGateway } from './organization.gateway';

describe('OrganizationGateway', () => {
  let gateway: OrganizationGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [OrganizationGateway],
    }).compile();

    gateway = module.get<OrganizationGateway>(OrganizationGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

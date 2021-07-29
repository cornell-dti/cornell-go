import { Test, TestingModule } from '@nestjs/testing';
import { GroupGateway } from './group.gateway';

describe('GroupGateway', () => {
  let gateway: GroupGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [GroupGateway],
    }).compile();

    gateway = module.get<GroupGateway>(GroupGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});

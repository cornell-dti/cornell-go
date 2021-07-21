import { Test, TestingModule } from '@nestjs/testing';
import { RefreshAccessController } from './refresh-access.controller';

describe('RefreshAccessController', () => {
  let controller: RefreshAccessController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [RefreshAccessController],
    }).compile();

    controller = module.get<RefreshAccessController>(RefreshAccessController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

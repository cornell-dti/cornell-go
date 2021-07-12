import { Test, TestingModule } from '@nestjs/testing';
import { AppleController } from './apple.controller';

describe('AppleController', () => {
  let controller: AppleController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AppleController],
    }).compile();

    controller = module.get<AppleController>(AppleController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

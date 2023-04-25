import { Test, TestingModule } from '@nestjs/testing';
import { AppleController } from './apple.controller';
import { AuthModule } from '../auth.module';

describe('AppleController', () => {
  let controller: AppleController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [AuthModule],
      controllers: [AppleController],
    }).compile();

    controller = module.get<AppleController>(AppleController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

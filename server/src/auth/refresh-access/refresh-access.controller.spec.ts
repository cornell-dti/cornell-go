import { Test, TestingModule } from '@nestjs/testing';
import { RefreshAccessController } from './refresh-access.controller';
import { AuthModule } from '../auth.module';

describe('RefreshAccessController', () => {
  let controller: RefreshAccessController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [AuthModule],
      controllers: [RefreshAccessController],
    }).compile();

    controller = module.get<RefreshAccessController>(RefreshAccessController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

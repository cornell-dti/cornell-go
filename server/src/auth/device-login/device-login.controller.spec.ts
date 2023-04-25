import { Test, TestingModule } from '@nestjs/testing';
import { DeviceLoginController } from './device-login.controller';
import { AuthModule } from '../auth.module';

describe('DeviceLoginController', () => {
  let controller: DeviceLoginController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [AuthModule],
      controllers: [DeviceLoginController],
    }).compile();

    controller = module.get<DeviceLoginController>(DeviceLoginController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { DeviceLoginController } from './device-login.controller';
import { AuthService } from '../auth.service';

describe('DeviceLoginController', () => {
  let controller: DeviceLoginController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [DeviceLoginController],
      providers: [{ useValue: null, provide: AuthService }],
    }).compile();

    controller = module.get<DeviceLoginController>(DeviceLoginController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

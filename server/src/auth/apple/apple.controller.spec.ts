import { Test, TestingModule } from '@nestjs/testing';
import { AppleController } from './apple.controller';
import { AuthService } from '../auth.service';
import { UserService } from '../../user/user.service';

describe('AppleController', () => {
  let controller: AppleController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AppleController],
      providers: [
        { useValue: null, provide: AuthService },
        { useValue: null, provide: UserService },
      ],
    }).compile();

    controller = module.get<AppleController>(AppleController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

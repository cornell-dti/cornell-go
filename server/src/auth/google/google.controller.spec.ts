import { Test, TestingModule } from '@nestjs/testing';
import { GoogleController } from './google.controller';
import { AuthService } from '../auth.service';

describe('GoogleController', () => {
  let controller: GoogleController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [GoogleController],
      providers: [{ useValue: null, provide: AuthService }],
    }).compile();

    controller = module.get<GoogleController>(GoogleController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

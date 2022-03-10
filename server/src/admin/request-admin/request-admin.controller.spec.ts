import { Test, TestingModule } from '@nestjs/testing';
import { RequestAdminController } from './request-admin.controller';

describe('RequestAdminController', () => {
  let controller: RequestAdminController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [RequestAdminController],
    }).compile();

    controller = module.get<RequestAdminController>(RequestAdminController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

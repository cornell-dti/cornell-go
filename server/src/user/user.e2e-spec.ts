import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { UserModule } from './user.module';
import { UserService } from './user.service';
import { AuthType } from '@prisma/client';

describe('UserModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [UserModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  it(`Create and check user`, async () => {
    const userService = moduleRef.get<UserService>(UserService);

    await userService.register(
      'test@example.com',
      'test',
      '2024',
      1,
      1,
      AuthType.DEVICE,
      'abcd',
      'Undergraduate',
    );

    const user = await userService.byAuth(AuthType.DEVICE, 'abcd');

    expect(user).toBeDefined();
    expect(user?.username).toEqual('test');
  });

  afterAll(async () => {
    await app.close();
  });
});

import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { UserService } from './user.service';
import { AuthType } from '@prisma/client';
import { AppModule } from '../app.module';

describe('UserModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  it('should successfully find UserService', async () => {
    const userService = moduleRef.get<UserService>(UserService);
    expect(userService).toBeDefined();
  });

  it(`should create and check user`, async () => {
    const userService = moduleRef.get<UserService>(UserService);

    await userService.register(
      'test1@example.com',
      'test1',
      '2024',
      1,
      1,
      AuthType.DEVICE,
      'abcd',
      'UNDERGRADUATE',
    );

    const user = await userService.byAuth(AuthType.DEVICE, 'abcd');
    expect(user).toBeDefined();
    expect(user?.username).toEqual('test1');
  });

  it(`should properly delete user`, async () => {
    const userService = moduleRef.get<UserService>(UserService);

    await userService.register(
      'test2@example.com',
      'test2',
      '2024',
      1,
      1,
      AuthType.DEVICE,
      'abcde',
      'UNDERGRADUATE',
    );

    const user = await userService.byAuth(AuthType.DEVICE, 'abcde');
    expect(user).toBeDefined();
    await userService.deleteUser(user!);
    expect(user).toBeNull;
  });

  it(`Checks the size of all the user data`, async () => {
    const userSer = moduleRef.get<UserService>(UserService);
    await userSer.register(
      'test4@example.com',
      'test4',
      '2024',
      1,
      1,
      AuthType.DEVICE,
      'abcdefg',
      'UNDERGRADUATE',
    );
    let oldList = await userSer.getAllUserData();
    await userSer.register(
      'test4@example.com',
      'test4',
      '2024',
      1,
      1,
      AuthType.DEVICE,
      'abcdefg',
      'UNDERGRADUATE',
    );
    let newList = await userSer.getAllUserData();
    expect(newList.length).toBeGreaterThan(oldList.length);
  });

  afterAll(async () => {
    await app.close();
  });
});

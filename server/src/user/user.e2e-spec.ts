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
      'test@example.com',
      'test',
      '2024',
      1,
      1,
      AuthType.DEVICE,
      'abcd',
      'UNDERGRADUATE',
    );

    const user = await userService.byAuth(AuthType.DEVICE, 'abcd');

    expect(user).toBeDefined();
    expect(user?.username).toEqual('test');
  });

  it(`should properly delete user`, async () => {
    const userService = moduleRef.get<UserService>(UserService)

    await userService.register(
      'test@example.com',
      'test',
      '2024',
      1,
      1,
      AuthType.DEVICE,
      'abcdef',
      'UNDERGRADUATE',
    );

    const user = await userService.byAuth(AuthType.DEVICE, 'abcdef');
    expect(user).toBeDefined();
    await userService.deleteUser(user!)
    expect(user).toBeNull
  })

  it(`Checking whether setUsername properly updates a user's username`, async () => {
    const userService = moduleRef.get<UserService>(UserService)
    await userService.register(
      'test@example.com',
      'test',
      '2024',
      1,
      1,
      AuthType.DEVICE,
      'abcdef',
      'UNDERGRADUATE',
    );
    const user = await userService.byAuth(AuthType.DEVICE, 'abcdef')
    userService.setUsername(user!, "newUser")
    expect(user?.username).toEqual("newUser")
  })

  it(``, async () => {
    const userService = moduleRef.get<UserService>(UserService)
    await userService.register(
      'test@example.com',
      'test',
      '2024',
      1,
      1,
      AuthType.DEVICE,
      'abcdef',
      'UNDERGRADUATE',
    );
    let users = userService.getAllUserData()
    expect((await users).length).toEqual(1)
    await userService.register(
      'test2@gmail.com',
      'test2',
      '2025',
      1,
      1,
      AuthType.DEVICE,
      'hello',
      'GRADUATE',
    );
    users = userService.getAllUserData()
    expect((await users).length).toEqual(1)
  })

  afterAll(async () => {
    await app.close();
  });
});

import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { UserService } from './user.service';
import { AuthType } from '@prisma/client';
import { AppModule } from '../app.module';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';

describe('UserModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;
  let fullAbility: AppAbility;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();

    fullAbility = moduleRef
      .get<CaslAbilityFactory>(CaslAbilityFactory)
      .createFull();
  });

  it('should successfully find UserService', async () => {
    const userService = moduleRef.get<UserService>(UserService);
    expect(userService).toBeDefined();
  });

  it(`should create and check user`, async () => {
    const userService = moduleRef.get<UserService>(UserService);

    await userService.register(
      'test1@example.com',
      '',
      '',
      '',
      '',
      [],
      1,
      1,
      AuthType.DEVICE,
      'auth1',
      'UNDERGRADUATE',
    );

    const user = await userService.byAuth(AuthType.DEVICE, 'auth1');
    expect(user).toBeDefined();
    expect(user?.username).toContain('guest');
  });

  it(`should properly delete user`, async () => {
    const userService = moduleRef.get<UserService>(UserService);

    await userService.register(
      'test2@example.com',
      '',
      '',
      '',
      '',
      [],
      1,
      1,
      AuthType.DEVICE,
      'auth2',
      'UNDERGRADUATE',
    );

    const user = await userService.byAuth(AuthType.DEVICE, 'auth2');
    expect(user).toBeDefined();
    await userService.deleteUser(fullAbility, user!);
    expect(user).toBeNull;
  });

  it(`Checks the size of all the user data`, async () => {
    const userSer = moduleRef.get<UserService>(UserService);
    await userSer.register(
      'test4@example.com',
      '23e21e',
      '23dwe',
      'Engineering',
      'Computer Science',
      ['Nature'],
      1,
      1,
      AuthType.DEVICE,
      'auth3',
      'UNDERGRADUATE',
    );
    let oldList = await userSer.getAllUserData();
    await userSer.register(
      'test4@example.com',
      'wefwef',
      'wef324f',
      'Engineering',
      'Computer Science',
      ['Food'],
      1,
      1,
      AuthType.DEVICE,
      'auth4',
      'UNDERGRADUATE',
    );
    let newList = await userSer.getAllUserData();
    expect(newList.length).toBeGreaterThan(oldList.length);
  });

  afterAll(async () => {
    await app.close();
  });
});

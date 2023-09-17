import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { GroupService } from './group.service';
import { AppModule } from '../app.module';

describe('GroupModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  it('should successfully find GroupService', async () => {
    const groupService = moduleRef.get<GroupService>(GroupService);

    expect(groupService).toBeDefined();
  });

  afterAll(async () => {
    await app.close();
  });
});

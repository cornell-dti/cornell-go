import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { SessionLogService } from './session-log.service';
import { AppModule } from '../app.module';

describe('SessionLogModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  it('should successfully find SessionLogService', async () => {
    const logService = moduleRef.get<SessionLogService>(SessionLogService);

    expect(logService).toBeDefined();
  });

  afterAll(async () => {
    await app.close();
  });
});

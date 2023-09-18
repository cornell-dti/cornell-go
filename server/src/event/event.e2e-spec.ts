import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { EventService } from './event.service';
import { AppModule } from '../app.module';

describe('EventModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  it('should successfully find EventService', async () => {
    const evService = moduleRef.get<EventService>(EventService);

    expect(evService).toBeDefined();
  });

  afterAll(async () => {
    await app.close();
  });
});

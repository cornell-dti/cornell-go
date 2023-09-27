import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { ChallengeService } from './challenge.service';
import { AppModule } from '../app.module';

describe('ChallengeModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  it('should successfully find ChallengeService', async () => {
    const chService = moduleRef.get<ChallengeService>(ChallengeService);

    expect(chService).toBeDefined();
  });

  afterAll(async () => {
    await app.close();
  });
});

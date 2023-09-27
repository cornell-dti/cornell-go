import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { RewardService } from './reward.service';
import { AppModule } from '../app.module';

describe('RewardModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  it('should successfully find RewardService', async () => {
    const rwService = moduleRef.get<RewardService>(RewardService);

    expect(rwService).toBeDefined();
  });

  afterAll(async () => {
    await app.close();
  });
});

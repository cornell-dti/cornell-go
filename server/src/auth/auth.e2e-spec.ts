import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AppModule } from '../app.module';

describe('AuthModule E2E', () => {
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
    const authService = moduleRef.get<AuthService>(AuthService);

    expect(authService).toBeDefined();
  });

  afterAll(async () => {
    await app.close();
  });
});

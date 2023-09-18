import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { OrganizationService } from './organization.service';
import { AppModule } from '../app.module';

describe('OrganizationModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  it('should successfully find OrganizationService', async () => {
    const orgService = moduleRef.get<OrganizationService>(OrganizationService);

    expect(orgService).toBeDefined();
  });

  afterAll(async () => {
    await app.close();
  });
});

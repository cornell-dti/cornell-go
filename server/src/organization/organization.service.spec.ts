import { Test, TestingModule } from '@nestjs/testing';
import { OrganizationService } from './organization.service';
import { ClientModule } from '../client/client.module';
import { PrismaModule } from '../prisma/prisma.module';

describe('OrganizationService', () => {
  let service: OrganizationService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [ClientModule, PrismaModule],
      providers: [OrganizationService],
    }).compile();

    service = module.get<OrganizationService>(OrganizationService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

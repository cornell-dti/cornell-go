import { Test, TestingModule } from '@nestjs/testing';
import { OrganizationService } from './organization.service';
import { PrismaService } from '../prisma/prisma.service';
import { ClientService } from '../client/client.service';
import { CaslAbilityFactory } from '../casl/casl-ability.factory';

describe('OrganizationService', () => {
  let service: OrganizationService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrganizationService,
        {
          useValue: null,
          provide: PrismaService,
        },
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: CaslAbilityFactory,
        },
      ],
    }).compile();

    service = module.get<OrganizationService>(OrganizationService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

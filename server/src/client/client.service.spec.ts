import { Test, TestingModule } from '@nestjs/testing';
import { ClientService } from './client.service';
import { ClientGateway } from './client.gateway';
import { CaslAbilityFactory } from '../casl/casl-ability.factory';
import { PrismaService } from '../prisma/prisma.service';

describe('ClientService', () => {
  let service: ClientService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ClientService,
        {
          useValue: null,
          provide: ClientGateway,
        },
        {
          useValue: null,
          provide: CaslAbilityFactory,
        },
        {
          useValue: null,
          provide: PrismaService,
        },
      ],
    }).compile();

    service = module.get<ClientService>(ClientService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

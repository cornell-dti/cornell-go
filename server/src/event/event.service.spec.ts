import { Test, TestingModule } from '@nestjs/testing';
import { EventService } from './event.service';
import { ClientService } from '../client/client.service';
import { OrganizationService } from '../organization/organization.service';
import { PrismaService } from '../prisma/prisma.service';

describe('EventService', () => {
  let service: EventService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EventService,
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: OrganizationService,
        },
        {
          useValue: null,
          provide: PrismaService,
        },
      ],
    }).compile();

    service = module.get<EventService>(EventService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

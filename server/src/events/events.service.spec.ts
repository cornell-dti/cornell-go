import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken, TypeOrmModule } from '@nestjs/typeorm';
import { EventBase } from '../model/event-base.entity';
import { EventProgress } from '../model/event-progress.entity';
import { EventReward } from '../model/event-reward.entity';
import { EventsService } from './events.service';

describe('EventsService', () => {
  let service: EventsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EventsService,
        {
          useValue: null,
          provide: getRepositoryToken(EventBase),
        },
        {
          useValue: null,
          provide: getRepositoryToken(EventReward),
        },
        {
          useValue: null,
          provide: getRepositoryToken(EventProgress),
        },
      ],
    }).compile();

    service = module.get<EventsService>(EventsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

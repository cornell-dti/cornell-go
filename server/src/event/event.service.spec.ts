import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken, TypeOrmModule } from '@nestjs/typeorm';
import { EventBase } from '../model/event-base.entity';
import { EventProgress } from '../model/event-progress.entity';
import { EventReward } from '../model/event-reward.entity';
import { EventService } from './event.service';

describe('EventService', () => {
  let service: EventService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EventService,
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

    service = module.get<EventService>(EventService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { EventsService } from '../events/events.service';
import { GroupsService } from '../groups/groups.service';
import { User } from '../model/user.entity';
import { UsersService } from './users.service';

describe('UsersService', () => {
  let service: UsersService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          useValue: null,
          provide: getRepositoryToken(User),
        },
        {
          useValue: null,
          provide: EventsService,
        },
        {
          useValue: null,
          provide: GroupsService,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

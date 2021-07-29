import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { EventService } from '../event/event.service';
import { GroupService } from '../group/group.service';
import { User } from '../model/user.entity';
import { UserService } from './user.service';

describe('UserService', () => {
  let service: UserService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UserService,
        {
          useValue: null,
          provide: getRepositoryToken(User),
        },
        {
          useValue: null,
          provide: EventService,
        },
        {
          useValue: null,
          provide: GroupService,
        },
      ],
    }).compile();

    service = module.get<UserService>(UserService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

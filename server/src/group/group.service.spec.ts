import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { EventBase, EventRewardType } from '../model/event-base.entity';
import { GroupMember } from '../model/group-member.entity';
import { Group } from '../model/group.entity';
import { AuthType, User } from '../model/user.entity';
import { GroupService } from './group.service';

describe('GroupService', () => {
  let service: GroupService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GroupService,
        { useValue: null, provide: getRepositoryToken(Group) },
        { useValue: null, provide: getRepositoryToken(GroupMember) },
      ],
    }).compile();

    service = module.get<GroupService>(GroupService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

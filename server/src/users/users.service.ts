import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { AuthType, User } from '../model/user.entity';
import { Repository } from 'typeorm';
import { EventsService } from '../events/events.service';
import { GroupMember } from '../model/group-member.entity';
import { GroupsService } from '../groups/groups.service';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private usersRepository: Repository<User>,
    private eventsService: EventsService,
    private groupsService: GroupsService,
  ) {}

  /** Find a user by their authentication token */
  async byAuth(authType: AuthType, authToken: string) {
    return await this.usersRepository.findOne({ authType, authToken });
  }

  /** Registers a user using a certain authentication scheme */
  async register(
    email: string,
    username: string,
    lat: number,
    long: number,
    authType: AuthType,
    authToken: string,
  ) {
    let user: User = this.usersRepository.create({
      score: 0,
      participatingEvents: [],
      logEntries: [],
      groupMember: null,
      username,
      email,
      authToken,
      authType,
    });

    let eventTracker = await this.eventsService.createDefaultEventTracker(
      user,
      lat,
      long,
    );

    let group = await this.groupsService.createFromEvent(
      eventTracker.event,
      user,
    );
  }
}

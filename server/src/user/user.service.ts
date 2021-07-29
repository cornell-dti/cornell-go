import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { AuthType, User } from '../model/user.entity';
import { Repository } from 'typeorm';
import { EventService } from '../event/event.service';
import { GroupMember } from '../model/group-member.entity';
import { GroupService } from '../group/group.service';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User) private usersRepository: Repository<User>,
    private eventsService: EventService,
    private groupsService: GroupService,
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
      participatingEvent: [],
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

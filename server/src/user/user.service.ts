import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { AuthType, User } from '../model/user.entity';
import { Repository } from 'typeorm';
import { EventService } from '../event/event.service';
import { GroupMember } from '../model/group-member.entity';
import { GroupService } from '../group/group.service';
import { AuthService } from '../auth/auth.service';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User) private usersRepository: Repository<User>,
    @Inject(forwardRef(() => EventService))
    private eventsService: EventService,
    private groupsService: GroupService,
  ) {}

  /** Find a user by their authentication token */
  async byAuth(authType: AuthType, authToken: string) {
    return await this.usersRepository.findOne({ authType, authToken });
  }

  /** Loads first-level relations and GroupMember.group/.currentEvent */
  async loadBasic(user: User) {
    return await this.usersRepository.findOneOrFail(user.id, {
      relations: [
        'participatingEvents',
        'participatingEvents.event',
        'participatingEvents.currentChallenge',
        'rewards',
        'groupMember',
        'groupMember.group',
        'groupMember.group.currentEvent',
      ],
    });
  }

  /** Loads the group of the user */
  async loadGroup(user: User, withMemberData: boolean) {
    let withGroup = await this.usersRepository.findOneOrFail(user.id, {
      relations: [
        ...(withMemberData
          ? [
              'groupMember.group',
              'groupMember.group.members',
              'groupMember.group.members.user',
              'currentEvent',
            ]
          : ['currentEvent']),
      ],
    });

    return withGroup.groupMember!.group;
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
      rewards: [],
      logEntries: [],
      groupMember: null,
      username,
      email,
      authToken,
      authType,
      hashedRefreshToken: '',
      superuser: false,
      adminGranted: false,
    });

    await this.usersRepository.save(user);

    let eventTracker = await this.eventsService.createDefaultEventTracker(
      user,
      lat,
      long,
    );

    user.participatingEvents = [eventTracker];
    await this.usersRepository.save(user);

    await this.groupsService.createFromEvent(eventTracker.event, user);

    return user;
  }

  /** Get the top N users by score */
  async getTopPlayers(firstIndex: number, count: number) {
    return await this.usersRepository.find({
      order: { score: 'DESC' },
      skip: firstIndex,
      take: count,
    });
  }

  async byId(id: string) {
    return await this.usersRepository.findOne({ id });
  }
}

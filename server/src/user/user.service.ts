import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { AuthType, User } from '../model/user.entity';
import { EventService } from '../event/event.service';
import { GroupService } from '../group/group.service';
import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { v4 } from 'uuid';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User) private usersRepository: EntityRepository<User>,
    @Inject(forwardRef(() => EventService))
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
      id: v4(),
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
      superuser: email === process.env.SUPERUSER,
      adminGranted:
        email === process.env.SUPERUSER || process.env.DEVELOPMENT === 'true',
      adminRequested: false,
    });

    const eventTracker = await this.eventsService.createDefaultEventTracker(
      user,
      lat,
      long,
    );

    user.participatingEvents.set([eventTracker]);

    await this.groupsService.createFromEvent(
      await eventTracker.event.load(),
      user,
    );

    await this.usersRepository.persistAndFlush(user);

    return user;
  }

  /** Get the top N users by score */
  async getTopPlayers(firstIndex: number, count: number) {
    return await this.usersRepository.findAll({
      orderBy: { score: 'DESC' },
      offset: firstIndex,
      limit: count,
    });
  }

  async byId(id: string) {
    return await this.usersRepository.findOne({ id });
  }
}

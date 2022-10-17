import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { EventService } from '../event/event.service';
import { GroupService } from '../group/group.service';
import { v4 } from 'uuid';
import { AuthType, Group, PrismaClient, User } from '@prisma/client';

@Injectable()
export class UserService {
  constructor(
    private prisma: PrismaClient,
    @Inject(forwardRef(() => EventService))
    private eventsService: EventService,
    private groupsService: GroupService,
  ) {}

  /** Find a user by their authentication token */
  async byAuth(authType: AuthType, authToken: string) {
    return await this.prisma.user.findFirst({ where: { authType, authToken } });
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
    const defEv = await this.eventsService.getDefaultEvent();

    const group: Group = await this.groupsService.createFromEvent(defEv);

    const user: User = await this.prisma.user.create({
      data: {
        score: 0,
        groupId: group.id,
        username,
        email,
        authToken,
        authType,
        hashedRefreshToken: '',
        superuser: email === process.env.SUPERUSER,
        adminGranted:
          email === process.env.SUPERUSER || process.env.DEVELOPMENT === 'true',
        adminRequested: false,
        isRanked: true,
      },
    });

    await this.eventsService.createDefaultEventTracker(user, lat, long);

    return user;
  }

  /** Get the top N users by score */
  async getTopPlayers(firstIndex: number, count: number) {
    return await this.prisma.user.findMany({
      where: { isRanked: true },
      orderBy: { score: 'desc' },
      skip: firstIndex,
      take: count,
    });
  }

  async byId(id: string) {
    return await this.prisma.user.findUnique({ where: { id } });
  }

  async deleteUser(user: User) {
    await this.groupsService.fixOrDeleteGroup(user.groupId);
    await this.prisma.user.delete({ where: { id: user.id } });
  }
}

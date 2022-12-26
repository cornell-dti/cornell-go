import { forwardRef, Inject, Injectable } from '@nestjs/common';
import {
  AuthType,
  Group,
  OrganizationSpecialUsage,
  User,
  PrismaClient,
} from '@prisma/client';
import { ClientService } from 'src/client/client.service';
import { EventService } from '../event/event.service';
import { GroupService } from '../group/group.service';
import { OrganizationService } from '../organization/organization.service';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto, UserAuthTypeDto, UserDto } from './user.dto';

@Injectable()
export class UserService {
  constructor(
    private prisma: PrismaService,
    private eventsService: EventService,
    @Inject(forwardRef(() => GroupService))
    private groupsService: GroupService,
    private orgService: OrganizationService,
    private clientService: ClientService,
  ) {}

  /** Find a user by their authentication token */
  async byAuth(authType: AuthType, authToken: string) {
    return await this.prisma.user.findFirst({ where: { authType, authToken } });
  }

  /** Sets a user's authentication type based on token */
  async setAuthType(user: User, authType: AuthType, token: string) {
    await this.prisma.user.update({
      where: { id: user.id },
      data: { authToken: token, authType: authType },
    });
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
    const defOrg = await this.orgService.getDefaultOrganization(
      authType == AuthType.GOOGLE
        ? OrganizationSpecialUsage.CORNELL_LOGIN
        : OrganizationSpecialUsage.DEVICE_LOGIN,
    );

    const group: Group = await this.groupsService.createFromEvent(
      await this.orgService.getDefaultEvent(defOrg),
    );

    const user: User = await this.prisma.user.create({
      data: {
        score: 0,
        group: { connect: { id: group.id } },
        hostOf: { connect: { id: group.id } },
        memberOf: { connect: { id: defOrg.id } },
        username,
        email,
        authToken,
        authType,
        hashedRefreshToken: '',
        administrator: email === process.env.SUPERUSER,
        isRanked: true,
      },
    });

    await this.eventsService.createDefaultEventTracker(user, lat, long);
    console.log(`User ${user.id} created!`);

    return user;
  }

  async byId(id: string) {
    return await this.prisma.user.findUnique({ where: { id } });
  }

  async deleteUser(user: User) {
    await this.prisma.user.delete({ where: { id: user.id } });
    await this.prisma.$transaction(async tx => {
      this.groupsService.fixOrDeleteGroup({ id: user.groupId }, tx);
    });
  }

  async setUsername(user: User, username: string) {
    await this.prisma.user.update({
      where: { id: user.id },
      data: { username },
    });
  }

  async dtoForUserData(user: User, partial: boolean): Promise<UserDto> {
    const joinedUser = await this.prisma.user.findUniqueOrThrow({
      where: { id: user.id },
      include: {
        rewards: true,
        eventTrackers: true,
        group: { select: { friendlyId: true } },
      },
    });

    return {
      id: joinedUser.id,
      username: joinedUser.username,
      score: joinedUser.score,
      groupId: joinedUser.group.friendlyId,
      authType: (
        joinedUser.authType as string
      ).toLowerCase() as UserAuthTypeDto,
      rewardIds: partial ? undefined : joinedUser.rewards.map(rw => rw.id),
      trackedEventIds: partial
        ? undefined
        : joinedUser.eventTrackers.map(ev => ev.eventId),
    };
  }

  async emitUpdateUserData(
    user: User,
    deleted: boolean,
    partial: boolean,
    admin?: boolean,
    client?: User,
  ) {
    const dto: UpdateUserDto = {
      user: deleted ? user.id : await this.dtoForUserData(user, partial),
      deleted,
    };

    if (client && admin) {
      this.clientService.sendUpdate('updateUserData', client.id, false, dto);
    } else if (admin) {
      this.clientService.sendUpdate('updateUserData', user.id, true, dto);
    }
  }
}

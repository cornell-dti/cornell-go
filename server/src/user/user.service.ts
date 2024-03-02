import { SessionLogService } from './../session-log/session-log.service';
import { forwardRef, Inject, Injectable } from '@nestjs/common';
import {
  AuthType,
  Group,
  SessionLogEvent,
  OrganizationSpecialUsage,
  User,
  PrismaClient,
  EnrollmentType,
  EventBase,
  PermissionType,
  RestrictedResourceType,
} from '@prisma/client';
import { ClientService } from '../client/client.service';
import { EventService } from '../event/event.service';
import { GroupService } from '../group/group.service';
import { OrganizationService } from '../organization/organization.service';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDataDto, UserAuthTypeDto, UserDto } from './user.dto';
import { PermissionService } from '../permission/permission.service';
import { CensorSensor } from 'censor-sensor';

@Injectable()
export class UserService {
  constructor(
    private log: SessionLogService,
    private prisma: PrismaService,
    private eventsService: EventService,
    @Inject(forwardRef(() => GroupService))
    private groupsService: GroupService,
    private orgService: OrganizationService,
    private clientService: ClientService,
    private permService: PermissionService,
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
    year: string,
    lat: number,
    long: number,
    authType: AuthType,
    authToken: string,
    enrollmentType: EnrollmentType,
  ) {
    if (username == null) username = email?.split('@')[0];

    const defOrg = await this.orgService.getDefaultOrganization(
      authType == AuthType.GOOGLE
        ? OrganizationSpecialUsage.CORNELL_LOGIN
        : OrganizationSpecialUsage.DEVICE_LOGIN,
    );

    const group = await this.groupsService.createFromEvent(
      await this.orgService.getDefaultEvent(defOrg),
    );

    const permGroupId = await this.permService.createPermissionGroup(
      null,
      'Default permission group for user',
    );

    const user = await this.prisma.user.create({
      data: {
        score: 0,
        group: { connect: { id: group.id } },
        hostOf: { connect: { id: group.id } },
        memberOf: { connect: { id: defOrg.id } },
        username,
        year,
        email,
        authToken,
        enrollmentType,
        authType,
        hashedRefreshToken: '',
        administrator:
          email === process.env.SUPERUSER || process.env.DEVELOPMENT === 'true',
        isRanked: true,
        defaultPermGroup: { connect: { id: permGroupId } },
      },
    });

    // grant access to self
    await this.permService.modifyPermissionGroup(
      permGroupId,
      PermissionType.READ_ONLY,
      null,
      user,
      RestrictedResourceType.USER,
      [user.id],
      null,
    );

    await this.permService.modifyPermissionGroup(
      permGroupId,
      PermissionType.READ_WRITE,
      null,
      user,
      RestrictedResourceType.USER,
      [user.id],
      ['username', 'enrollmentType', 'email', 'year'],
    );

    // grant access to group
    await this.permService.modifyPermissionGroup(
      permGroupId,
      PermissionType.READ_WRITE,
      null,
      user,
      RestrictedResourceType.GROUP,
      [user.groupId],
      ['members', 'curEventId'],
    );

    // TODO: GRANT ACCESS TO ORGANIZATION

    await this.eventsService.createDefaultEventTracker(user, lat, long);
    console.log(`User ${user.id} created!`);
    await this.log.logEvent(SessionLogEvent.CREATE_USER, user.id, user.id);

    return user;
  }

  async byId(id: string) {
    return await this.prisma.user.findUnique({ where: { id } });
  }

  async byEmail(email: string) {
    return await this.prisma.user.findFirstOrThrow({ where: { email: email } });
  }

  async getAllUserData() {
    return await this.prisma.user.findMany();
  }

  async deleteUser(user: User) {
    await this.log.logEvent(SessionLogEvent.DELETE_USER, user.id, user.id);
    await this.prisma.user.delete({ where: { id: user.id } });
    await this.prisma.$transaction(async tx => {
      await this.groupsService.fixOrDeleteGroup({ id: user.groupId }, tx);
    });
  }

  /** Adds event to user's favorite if isFavorite is true, else removes event
   * from favorites if it exists */
  async setFavorite(user: User, ev: EventBase, isFavorite: boolean) {
    if (isFavorite) {
      return await this.prisma.user.update({
        where: { id: user.id },
        data: { favorites: { connect: { id: ev.id } } },
      });
    } else {
      return await this.prisma.user.update({
        where: { id: user.id },
        data: { favorites: { disconnect: { id: ev.id } } },
      });
    }
  }

  /**
   * Ban a user based on their user id.
   * @param user the user who will be banned.
   * @param isBanned a boolean which represents the user's banned status
   * @returns A promise containing the new user if successful.
   */
  async banUser(user: User, isBanned: boolean): Promise<User> {
    return await this.prisma.user.update({
      where: { id: user.id },
      data: {
        isBanned,
      },
    });
  }

  /**
   * Update a User's username, email, or year.
   * @param user User requiring an update.
   * @returns The new user after the update is made
   */
  async updateUser(accessor: User, user: UserDto): Promise<User> {
    const data = {
      username: user.username
        ? new CensorSensor()
            .cleanProfanityIsh(
              user.username
                .substring(0, 128)
                .replaceAll(/[^_A-z0-9]/g, ' ')
                .replaceAll('_', ' '),
            )
            .replaceAll('*', '_')
            .replaceAll(' ', '_')
        : undefined,
      email: user.email,
      year: user.year,
    };

    await this.permService.deleteForbiddenProperties(
      accessor,
      PermissionType.READ_WRITE,
      RestrictedResourceType.USER,
      [data],
      [user.id],
    );

    return await this.prisma.user.update({
      where: { id: user.id },
      data,
    });
  }

  async dtoForUserData(user: User, partial: boolean): Promise<UserDto> {
    const joinedUser = await this.prisma.user.findUniqueOrThrow({
      where: { id: user.id },
      include: {
        eventTrackers: true,
        favorites: true,
        group: { select: { friendlyId: true } },
      },
    });

    const dto: UserDto = {
      id: joinedUser.id,
      username: joinedUser.username,
      enrollmentType: joinedUser.enrollmentType,
      email: joinedUser.email,
      year: joinedUser.year,
      score: joinedUser.score,
      groupId: joinedUser.group.friendlyId,
      isBanned: joinedUser.isBanned,
      authType: (
        joinedUser.authType as string
      ).toLowerCase() as UserAuthTypeDto,
      trackedEventIds: partial
        ? undefined
        : joinedUser.eventTrackers.map(ev => ev.eventId),
      favoriteIds: partial
        ? undefined
        : joinedUser.favorites.map((ev: EventBase) => ev.id),
    };

    return dto;
  }

  async emitUpdateUserData(
    user: User,
    deleted: boolean,
    partial: boolean,
    receiver?: User,
  ) {
    const dto: UpdateUserDataDto = {
      user: deleted
        ? { id: user.id }
        : await this.dtoForUserData(user, partial),
      deleted,
    };

    await this.permService.sendUpdateProtected(
      'updateUserData',
      user.id,
      RestrictedResourceType.USER,
      dto,
      receiver,
    );

    await this.log.logEvent(SessionLogEvent.EDIT_USERNAME, user.id, user.id);
  }
}

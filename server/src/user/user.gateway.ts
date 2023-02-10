import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { AuthType, User } from '@prisma/client';
import { CensorSensor } from 'censor-sensor';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { GroupGateway } from '../group/group.gateway';
import { GroupService } from '../group/group.service';
import {
  CloseAccountDto,
  RequestGlobalLeaderDataDto,
  RequestUserDataDto,
  SetAuthToDeviceDto,
  SetAuthToOAuthDto,
  SetGraduationYearDto,
  SetMajorDto,
  SetUsernameDto,
} from './user.dto';
import { UserService } from './user.service';
import { readFileSync } from 'fs';

const majors = readFileSync("./majors.txt",'utf8').split('\n');
const replaceAll = require('string.prototype.replaceall');
replaceAll.shim();

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class UserGateway {
  constructor(
    private clientService: ClientService,
    private userService: UserService,
    private groupService: GroupService,
  ) {}

  private providerToAuthType(provider: string) {
    let type: AuthType = AuthType.NONE;
    switch (provider) {
      case 'google':
        type = AuthType.GOOGLE;
        break;
      case 'apple':
        type = AuthType.APPLE;
        break;
      case 'device':
        type = AuthType.DEVICE;
        break;
    }
    return type;
  }

  @SubscribeMessage('requestUserData')
  async requestUserData(
    @CallingUser() user: User,
    @MessageBody() data: RequestUserDataDto,
  ) {
    if (user.administrator && data.userId) {
      const queried = await this.userService.byId(data.userId);

      if (queried) {
        await this.userService.emitUpdateUserData(
          queried,
          false,
          false,
          true,
          user,
        );
      }
    } else {
      await this.userService.emitUpdateUserData(user, false, false, true, user);
    }
  }

  @SubscribeMessage('setUsername')
  async setUsername(
    @CallingUser() user: User,
    @MessageBody() data: SetUsernameDto,
  ) {
    const username = new CensorSensor()
      .cleanProfanityIsh(
        data.newUsername
          .substring(0, 128)
          .replaceAll(/[^_A-z0-9]/g, ' ')
          .replaceAll('_', ' '),
      )
      .replaceAll('*', '_')
      .replaceAll(' ', '_');

    await this.userService.setUsername(user, username);

    user.username = username; // Updated so change here too

    await this.userService.emitUpdateUserData(user, false, true, true);

    const group = await this.groupService.getGroupForUser(user);
    await this.groupService.emitUpdateGroupData(group, false);
  }

  @SubscribeMessage('setMajor')
  async setMajor(@CallingUser() user: User, @MessageBody() data: SetMajorDto) {
    if (majors.includes(data.newMajor)) {
      await this.userService.setMajor(user, data.newMajor);

      user.major = data.newMajor; // Updated so change here too

      await this.userService.emitUpdateUserData(user, false, true, true);
    }
  }

  @SubscribeMessage('setGraduationYear')
  async setGraduationYear(
    @CallingUser() user: User,
    @MessageBody() data: SetGraduationYearDto,
  ) {
    await this.userService.setGraduationYear(user, data.newYear);

    user.year = data.newYear; // Updated so change here too

    await this.userService.emitUpdateUserData(user, false, true, true);
  }

  @SubscribeMessage('setAuthToDevice')
  async setAuthToDevice(
    @CallingUser() user: User,
    @MessageBody() data: SetAuthToDeviceDto,
  ) {
    await this.userService.setAuthType(user, AuthType.DEVICE, data.deviceId);
  }

  @SubscribeMessage('setAuthToOAuth')
  async setAuthToOAuth(
    @CallingUser() user: User,
    @MessageBody() data: SetAuthToOAuthDto,
  ) {
    await this.userService.setAuthType(
      user,
      this.providerToAuthType(data.provider),
      data.authId,
    );
  }

  @SubscribeMessage('closeAccount')
  async closeAccount(
    @CallingUser() user: User,
    @MessageBody() data: CloseAccountDto,
  ) {
    const group = await this.groupService.getGroupForUser(user);
    await this.userService.setAuthType(user, AuthType.NONE, user.authToken);
    await this.userService.deleteUser(user);
    await this.groupService.emitUpdateGroupData(group, false);
  }
}

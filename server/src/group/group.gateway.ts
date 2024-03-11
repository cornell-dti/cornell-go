import { EventService } from '../event/event.service';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import {
  GroupDto,
  JoinGroupDto,
  LeaveGroupDto,
  RequestGroupDataDto,
  SendGroupInviteDto,
  SetCurrentEventDto,
  UpdateGroupDataDto,
} from './group.dto';
import { GroupService } from './group.service';
import { UserGuard } from '../auth/jwt-auth.guard';
import { UseGuards } from '@nestjs/common';
import { Group, User } from '@prisma/client';
import { PoliciesGuard } from '../casl/policy.guard';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class GroupGateway {
  constructor(
    private clientService: ClientService,
    private groupService: GroupService,
  ) {}

  @SubscribeMessage('requestGroupData')
  async requestGroupData(
    @CallingUser() user: User,
    @MessageBody() data: RequestGroupDataDto,
  ) {
    const group = await this.groupService.getGroupForUser(user);
    this.clientService.subscribe(user, group.id, user.administrator);
    this.groupService.emitUpdateGroupData(
      group,
      false,
      user.administrator,
      user,
    );
  }

  @SubscribeMessage('joinGroup')
  async joinGroup(
    @CallingUser() user: User,
    @MessageBody() data: JoinGroupDto,
  ) {
    const oldGroup = await this.groupService.joinGroup(user, data.groupId);
    await this.groupService.updateGroupMembers(user, oldGroup);
  }

  @SubscribeMessage('leaveGroup')
  async leaveGroup(
    @CallingUser() user: User,
    @MessageBody() data: LeaveGroupDto,
  ) {
    const oldGroup = await this.groupService.leaveGroup(user);
    await this.groupService.updateGroupMembers(user, oldGroup);
  }

  /**
   * Sets the current event of the user to the event of data. If event can not be properlly joined, an error is emitted instead of the user's group.
   *
   * @param user The Calling user
   * @param data EventId of the event to set
   */
  @SubscribeMessage('setCurrentEvent')
  async setCurrentEvent(
    @CallingUser() user: User,
    @MessageBody() data: SetCurrentEventDto,
  ) {
    if (await this.groupService.setCurrentEvent(user, data.eventId)) {
      const group = await this.groupService.getGroupForUser(user);
      await this.groupService.emitUpdateGroupData(group, false);
    } else {
      await this.clientService.emitErrorData(
        user,
        'Error setting current event',
      );
    }
  }

  @SubscribeMessage('updateGroupData')
  async updateGroupData(
    @CallingUser() user: User,
    @MessageBody() data: UpdateGroupDataDto,
  ) {
    if (!user.administrator) {
      await this.clientService.emitErrorData(user, 'User is not an admin');
      return;
    }

    if (data.deleted) {
      await this.groupService.removeGroup(data.group as string);
    } else {
      const group = await this.groupService.updateGroup(data.group as GroupDto);
      await this.groupService.emitUpdateGroupData(group, false);
    }
  }

  @SubscribeMessage('sendGroupInvite')
  async sendGroupInvite(
    @CallingUser() user: User,
    @MessageBody() data: SendGroupInviteDto,
  ) {
    const group = await this.groupService.getGroupForUser(user);
    await this.groupService.emitGroupInvite(group, data.targetUsername, user);
  }
}

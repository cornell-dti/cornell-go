import { EventService } from '../event/event.service';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import {
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
import { User } from '@prisma/client';
import { PoliciesGuard } from '../casl/policy.guard';
import { UserAbility } from '../casl/user-ability.decorator';
import { AppAbility } from '../casl/casl-ability.factory';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';

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
    await this.groupService.emitUpdateGroupData(group, false, user);
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
    await this.groupService.setCurrentEvent(user, data.eventId);
    const group = await this.groupService.getGroupForUser(user);
    await this.groupService.emitUpdateGroupData(group, false, user);
  }

  @SubscribeMessage('updateGroupData')
  async updateGroupData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: UpdateGroupDataDto,
  ) {
    const group = await this.groupService.getGroupById(data.group.id);
    if (!group) {
      await this.clientService.emitErrorData(
        user,
        'This group does not exist!',
      );
      return;
    }

    if (data.deleted) {
      if (!(await this.groupService.removeGroup(ability, data.group.id))) {
        await this.clientService.emitErrorData(user, 'Failed to remove group!');
      }
      await this.groupService.emitUpdateGroupData(group, true);
    } else {
      const group = await this.groupService.updateGroup(ability, data.group);
      this.clientService.subscribe(user, group.id);
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

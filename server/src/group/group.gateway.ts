import { EventService } from 'src/event/event.service';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { JoinGroupDto } from './join-group.dto';
import { LeaveGroupDto } from './leave-group.dto';
import { RequestGroupDataDto } from './request-group-data.dto';
import { SetCurrentEventDto } from './set-current-event.dto';
import {
  UpdateGroupDataDto,
  UpdateGroupDataMemberDto,
} from '../client/update-group-data.dto';
import { GroupService } from './group.service';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { UseGuards } from '@nestjs/common';
import { UpdateUserDataAuthTypeDto } from '../client/update-user-data.dto';
import { Group, User } from '@prisma/client';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
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
    const groupData = await this.groupService.getGroupForUser(user);

    const updateGroupData: UpdateGroupDataDto = {
      curEventId: groupData.curEventId,
      members: await this.groupService.dtoForMemberData(groupData),
      removeListedMembers: false,
    };

    this.clientService.emitUpdateGroupData(user, updateGroupData);
    return false;
  }

  /** Helper function that notifies the user, all old group members,
   * and all new members that the user has moved groups. */
  async notifyAll(user: User, oldGroup: Group | undefined) {
    if (oldGroup) {
      const oldMembers = await this.groupService.getMembers(oldGroup);
      for (const member of oldMembers) {
        await this.requestGroupData(member, {});
      }
    }
    const newMembers = await this.groupService.getMembers({ id: user.groupId });
    for (const member of newMembers) {
      await this.requestGroupData(member, {});
    }
  }

  /** Helper function that notifies the user of a change in group */
  async notifyUser(user: User) {
    const group = await this.groupService.getGroupForUser(user);
    await this.clientService.emitUpdateUserData(user, {
      id: user.id,
      username: user.username,
      score: user.score,
      groupId: group.friendlyId,
      rewardIds: [],
      trackedEventIds: [],
      ignoreIdLists: true,
      authType: user.authType as UpdateUserDataAuthTypeDto,
    });
  }

  @SubscribeMessage('joinGroup')
  async joinGroup(
    @CallingUser() user: User,
    @MessageBody() data: JoinGroupDto,
  ) {
    const oldGroup = await this.groupService.joinGroup(user, data.groupId);
    await this.notifyAll(user, oldGroup);
    await this.notifyUser(user);
  }

  @SubscribeMessage('leaveGroup')
  async leaveGroup(
    @CallingUser() user: User,
    @MessageBody() data: LeaveGroupDto,
  ) {
    const oldGroup = await this.groupService.leaveGroup(user);
    await this.notifyAll(user, oldGroup);
    await this.notifyUser(user);
  }

  @SubscribeMessage('setCurrentEvent')
  async setCurrentEvent(
    @CallingUser() user: User,
    @MessageBody() data: SetCurrentEventDto,
  ) {
    const members = await this.groupService.setCurrentEvent(user, data.eventId);

    members?.forEach(async (member: User) => {
      await this.requestGroupData(member, {});
    });
  }
}

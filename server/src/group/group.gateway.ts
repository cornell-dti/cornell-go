import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { User } from '../model/user.entity';
import { JoinGroupDto } from './join-group.dto';
import { LeaveGroupDto } from './leave-group.dto';
import { RequestGroupDataDto } from './request-group-data.dto';
import { SetCurrentEventDto } from './set-current-event.dto';
import {
  UpdateGroupDataDto,
  UpdateGroupDataMemberDto,
} from '../client/update-group-data.dto';
import { GroupService } from './group.service';
import { GroupMember } from '../model/group-member.entity';
import { EventService } from '../event/event.service';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { UseGuards } from '@nestjs/common';
@WebSocketGateway()
@UseGuards(UserGuard)
export class GroupGateway {
  constructor(
    private clientService: ClientService,
    private groupService: GroupService,
    private eventService: EventService,
  ) { }

  @SubscribeMessage('requestGroupData')
  async requestGroupData(
    @CallingUser() user: User,
    @MessageBody() data: RequestGroupDataDto,
  ) {
    const groupData = await this.groupService.getGroupForUser(user);

    const updateGroupData: UpdateGroupDataDto = {
      curEventId: groupData.currentEvent.id,
      members: await Promise.all(
        (
          await groupData.members.loadItems()
        ).map(async member => {
          const usr = await member.user.load();
          return {
            id: usr.id,
            name: usr.username,
            points: usr.score,
            host: member.isHost,
            curChallengeId: (
              await this.eventService.getCurrentEventTrackerForUser(usr)
            ).event.id,
          };
        }),
      ),
      removeListedMembers: false,
    };

    this.clientService.emitUpdateGroupData(user, updateGroupData);
    return false;
  }

  @SubscribeMessage('joinGroup')
  async joinGroup(
    @CallingUser() user: User,
    @MessageBody() data: JoinGroupDto,
  ) {
    this.groupService.joinGroup(user, data.groupId);
    this.requestGroupData(user, {})
  }

  @SubscribeMessage('leaveGroup')
  async leaveGroup(
    @CallingUser() user: User,
    @MessageBody() data: LeaveGroupDto,
  ) {
    this.groupService.leaveGroup(user);
    this.requestGroupData(user, {})
  }

  @SubscribeMessage('setCurrentEvent')
  async setCurrentEvent(
    @CallingUser() user: User,
    @MessageBody() data: SetCurrentEventDto,
  ) { }
}

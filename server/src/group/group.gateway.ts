import { EventService } from 'src/event/event.service';
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
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { UseGuards } from '@nestjs/common';
import { group } from 'console';
@WebSocketGateway()
@UseGuards(UserGuard)
export class GroupGateway {
  constructor(
    private clientService: ClientService,
    private groupService: GroupService,
    private eventService: EventService,
  ) {}

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
        ).map(async (member: GroupMember) => {
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
  ) {}

  @SubscribeMessage('leaveGroup')
  async leaveGroup(
    @CallingUser() user: User,
    @MessageBody() data: LeaveGroupDto,
  ) {}

  @SubscribeMessage('setCurrentEvent')
  async setCurrentEvent(
    @CallingUser() user: User,
    @MessageBody() data: SetCurrentEventDto,
  ) {
    const userMember = await user.groupMember!.load();
    const userGroup = await userMember.group.load();
    let newEvent = (await this.eventService.getEventsByIds([data.eventId]))[0];
    let groupMembers = await userGroup.members.loadItems();
    groupMembers.forEach(async (member: GroupMember) => {
      //if the user already has the event, keep their tracker
      let currentUser = await member.user.load();
      const evTrackers = await this.eventService.getEventTrackersByEventId(
        user,
        [data.eventId],
      );
      if (evTrackers.length === 0)
        this.eventService.createEventTracker(currentUser, newEvent);
    });
    userGroup.currentEvent.set(newEvent);
    await this.groupService.saveGroup(userGroup);
    let updateGroupData: UpdateGroupDataDto = {
      curEventId: data.eventId,
      members: [],
      removeListedMembers: false,
    };
    groupMembers.forEach(async (member: GroupMember) => {
      this.clientService.emitUpdateGroupData(
        await member.user.load(),
        updateGroupData,
      );
    });
  }
}

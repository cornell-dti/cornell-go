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
import { Group } from 'src/model/group.entity';

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

  /** Helper function that notifies the user, all old group members,
   * and all new members that the user has moved groups. */
  async notifyAll(user: User, oldGroup: Group | null) {
    this.requestGroupData(user, {});
    if (oldGroup != null) {
      const oldMembers = oldGroup!.members;
      for (const member of oldMembers) {
        this.requestGroupData(await member.user.load(), {});
      }
    }
    const newMembers = (await this.groupService.getGroupForUser(user)).members;
    for (const member of newMembers) {
      this.requestGroupData(await member.user.load(), {});
    }
  }

  @SubscribeMessage('joinGroup')
  async joinGroup(
    @CallingUser() user: User,
    @MessageBody() data: JoinGroupDto,
  ) {
    const oldGroup = await this.groupService.joinGroup(user, data.groupId);
    this.notifyAll(user, oldGroup);
  }

  @SubscribeMessage('leaveGroup')
  async leaveGroup(
    @CallingUser() user: User,
    @MessageBody() data: LeaveGroupDto,
  ) {
    const oldGroup = await this.groupService.leaveGroup(user);
    this.notifyAll(user, oldGroup);
  }

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

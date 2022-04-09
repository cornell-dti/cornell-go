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
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { UseGuards } from '@nestjs/common';
import { Group } from 'src/model/group.entity';
import { UpdateUserDataAuthTypeDto } from '../client/update-user-data.dto';

@WebSocketGateway({ cors: true })
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
        ).map(async (member: User) => {
          return {
            id: member.id,
            name: member.username,
            points: member.score,
            host: member.id === groupData.host?.id,
            curChallengeId: (
              await this.eventService.getCurrentEventTrackerForUser(member)
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
  async notifyAll(user: User, oldGroup: Group | undefined) {
    if (oldGroup) {
      const oldMembers = oldGroup.members;
      for (const member of oldMembers) {
        await this.requestGroupData(member, {});
      }
    }
    const newMembers = (await this.groupService.getGroupForUser(user)).members;
    for (const member of newMembers) {
      await this.requestGroupData(member, {});
    }
  }

  /** Helper function that notifies the user of a change in group */
  async notifyUser(user: User) {
    const group = await user.group.load();
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
    const group = await user.group?.load();
    if (group?.host?.id !== user.id) {
      return;
    }
    let newEvent = (await this.eventService.getEventsByIds([data.eventId]))[0];
    let groupMembers = await group.members.loadItems();
    groupMembers.forEach(async (member: User) => {
      //if the user already has the event, keep their tracker
      const evTrackers = await this.eventService.getEventTrackersByEventId(
        user,
        [data.eventId],
      );
      if (evTrackers.length === 0)
        this.eventService.createEventTracker(member, newEvent);
    });
    group.currentEvent.set(newEvent);
    await this.groupService.saveGroup(group);
    groupMembers.forEach(async (member: User) => {
      this.requestGroupData(member, {});
    });
  }
}

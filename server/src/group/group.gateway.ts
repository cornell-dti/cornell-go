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
@WebSocketGateway()
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
    const authToken: string = data.accessToken;
    await this.groupService.requestGroupData(authToken);
    //TODO: 1. search user repository(implemented in service)
    // TODO:2. construct updateGroupData
    // const updateGroupData: UpdateGroupDataDto = {
    //   curEventId: "id",
    //   members: UpdateGroupDataMemberDto[],
    //   update: true,
    // };
    // TODO: 3.call clientService
    //this.clientService.emitUpdateGroupData(user, updateGroupData);
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
    const userMember = await user.groupMember!.load()
    const userGroup = await userMember.group.load();
    let newEvent = await this.eventService.getEventsByIds(
      [data.eventId],

    );
    userGroup.members.forEach(async member => {
      //if the user already has the event, keep their tracker
      try {
        let memberEvent = await this.eventService.getCurrentEventTrackerForUser(
          member.user,
        );
        if (memberEvent.event.id != data.eventId)
          this.eventService.createEventTracker(member.user, newEvent[0]);
        //else add a new tracker to the current event
      } catch {
        this.eventService.createEventTracker(member.user, newEvent[0]);
      }
    });
    userGroup.currentEvent.set(newEvent);
    await this.groupService.saveGroup(userGroup);
    let updateGroupData: UpdateGroupDataDto = {
      curEventId: data.eventId,
      members: [],
      update: false,
    };
    this.clientService.emitUpdateGroupData(user, updateGroupData);
  }
}

import { Injectable } from '@nestjs/common';
import { User } from '../model/user.entity';
import { ClientGateway } from './client.gateway';
import { InvalidateDataDto } from './invalidate-data.dto';
import { UpdateChallengeDataDto } from './update-challenge-data.dto';
import { UpdateEventDataDto } from './update-event-data.dto';
import { UpdateEventTrackerDataDto } from './update-event-tracker-data.dto';
import { UpdateGroupDataDto } from './update-group-data.dto';
import { UpdateLeaderDataDto } from './update-leader-data.dto';
import { UpdateRewardDataDto } from './update-reward-data.dto';
import { UpdateUserDataDto } from './update-user-data.dto';
import { UserRewardedDto } from './user-rewarded.dto';

@Injectable()
export class ClientService {
  constructor(private gateway: ClientGateway) {}

  private makeCallback<TData>(event: string) {
    return (user: User, data: TData) => {
      console.log(`Sent ${event} to user ${user.id}`);
      this.gateway.server.to(user.id).emit(event, data);
    };
  }

  emitUpdateUserData = this.makeCallback<UpdateUserDataDto>('updateUserData');

  emitUserRewarded = this.makeCallback<UserRewardedDto>('userRewarded');

  emitInvalidateData(data: InvalidateDataDto) {
    this.gateway.server.emit('invalidateData', data);
  }

  emitUpdateRewardData =
    this.makeCallback<UpdateRewardDataDto>('updateRewardData');

  emitUpdateEventData =
    this.makeCallback<UpdateEventDataDto>('updateEventData');

  emitUpdateLeaderData =
    this.makeCallback<UpdateLeaderDataDto>('updateLeaderData');

  emitUpdateGroupData =
    this.makeCallback<UpdateGroupDataDto>('updateGroupData');

  emitUpdateEventTrackerData = this.makeCallback<UpdateEventTrackerDataDto>(
    'updateEventTrackerData',
  );

  emitUpdateChallengeData = this.makeCallback<UpdateChallengeDataDto>(
    'updateChallengeData',
  );
}

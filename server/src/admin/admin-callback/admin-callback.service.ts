import { Injectable } from '@nestjs/common';
import { ClientGateway } from 'src/client/client.gateway';
import { User } from 'src/model/user.entity';
import { UpdateAdminDataDto } from './update-admin-data.dto';
import { UpdateChallengeDataDto } from './update-challenge-data.dto';
import { UpdateEventDataDto } from './update-event-data.dto';
import { UpdateRewardDataDto } from './update-reward-data.dto';

@Injectable()
export class AdminCallbackService {
  constructor(private gateway: ClientGateway) {}

  private makeCallback<TData>(event: string) {
    return (data: TData, user?: User) => {
      if (user && user.adminGranted) {
        this.gateway.server.to(user.id).emit(event, data);
      } else {
        this.gateway.server.to('admins').emit(event, data);
      }
    };
  }

  emitUpdateAdminData =
    this.makeCallback<UpdateAdminDataDto>('updateAdminData');

  emitUpdateChallengeData = this.makeCallback<UpdateChallengeDataDto>(
    'updateChallengeData',
  );

  emitUpdateEventData =
    this.makeCallback<UpdateEventDataDto>('updateEventData');

  emitUpdateRewardData =
    this.makeCallback<UpdateRewardDataDto>('updateRewardData');
}

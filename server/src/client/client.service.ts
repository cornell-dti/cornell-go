import { Injectable } from '@nestjs/common';
import { User } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';
import { UpdateErrorDto } from './client.dto';
import { ClientGateway } from './client.gateway';

@Injectable()
export class ClientService {
  constructor(private gateway: ClientGateway) {}

  public sendUpdate<TDto>(
    event: string,
    resourceId: string,
    admin: boolean,
    dto: TDto,
  ) {
    this.gateway.server
      .to((admin ? 'admin/' : 'client/') + resourceId)
      .emit(event, dto);
  }

  public subscribe(user: User, resourceId: string, admin: boolean) {
    this.gateway.server
      .in('client/' + user.id)
      .socketsJoin((admin ? 'admin/' : 'client/') + resourceId);
  }

  public unsubscribe(user: User, resourceId: string, admin: boolean) {
    this.gateway.server
      .in('client/' + user.id)
      .socketsLeave((admin ? 'admin/' : 'client/') + resourceId);
  }

  public unsubscribeAll(resourceId: string) {
    this.gateway.server.socketsLeave([
      'admin/' + resourceId,
      'client/' + resourceId,
    ]);
  }

  async emitErrorData(user: User, message: string) {
    const dto: UpdateErrorDto = {
      message,
    };
    this.sendUpdate('updateErrorData', user.id, false, dto);
  }

  /*
  async updateUserData(user: User) {
    this.sendUpdate<ClientUserDto>('updateUserData', user.id, false);
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
  */
}

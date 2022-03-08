import { Injectable } from '@nestjs/common';
import { ClientGateway } from 'src/client/client.gateway';
import { User } from 'src/model/user.entity';

@Injectable()
export class AdminCallbackService {
  constructor(private gateway: ClientGateway) {}

  private makeCallback<TData>(event: string) {
    return (user: User, data: TData) => {
      if (user.adminGranted) this.gateway.server.to(user.id).emit(event, data);
    };
  }

  //emitUpdateAdminData = make
}

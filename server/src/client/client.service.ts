import { Injectable } from '@nestjs/common';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateErrorDto } from './client.dto';
import { ClientGateway } from './client.gateway';
import { tokenOfHandshake } from '../auth/jwt-auth.guard';

@Injectable()
export class ClientService {
  constructor(private gateway: ClientGateway) {}

  public sendUpdate<TDto>(event: string, resourceId: string, dto: TDto) {
    this.gateway.server.to(resourceId).emit(event, dto);
  }

  public subscribe(user: User, resourceId: string) {
    this.gateway.server.in(user.id).socketsJoin(resourceId);
  }

  public unsubscribe(user: User, resourceId: string, admin: boolean) {
    this.gateway.server.in(user.id).socketsLeave(resourceId);
  }

  public unsubscribeAll(resourceId: string) {
    this.gateway.server.socketsLeave([resourceId]);
  }

  public async getUserTokensInRoom(resourceId: string) {
    const sockets = await this.gateway.server.in(resourceId).fetchSockets();
    return sockets.map(sock => tokenOfHandshake(sock.handshake));
  }

  async emitErrorData(user: User, message: string) {
    const dto: UpdateErrorDto = {
      message,
    };
    this.sendUpdate('updateErrorData', user.id, dto);
  }
}

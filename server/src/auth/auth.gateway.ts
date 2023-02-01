import {
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { AuthService } from './auth.service';

@WebSocketGateway()
export class AuthGateway implements OnGatewayConnection {
  constructor(private authService: AuthService) {}
  async handleConnection(client: Socket, ...args: any[]) {
    const token =
      client.handshake.auth['token'] ?? client.handshake.query['token'];
    const user = await this.authService.userByToken(token);
    if (user) {
      client.join(['client/' + user.id, 'admin/' + user.id]);
      for (const id of await this.authService.getManagedOrgIds(user)) {
        client.join(id);
      }
    } else {
      client.disconnect(true);
    }
  }
}

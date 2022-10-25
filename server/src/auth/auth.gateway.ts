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
      client.join(user.id);
      if (user.adminGranted) {
        console.log(`Admin ${user.id} joined admins`);
        client.join('admins');
      }
    } else {
      client.disconnect(true);
    }
  }
}

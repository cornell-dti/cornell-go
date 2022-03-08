import {
  OnGatewayConnection,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { AuthService } from 'src/auth/auth.service';

@WebSocketGateway()
export class ClientGateway implements OnGatewayConnection {
  constructor(private authService: AuthService) {}
  async handleConnection(client: Socket, ...args: any[]) {
    const token =
      client.handshake.auth['token'] ?? client.handshake.query['token'];
    const user = await this.authService.userByToken(token);
    if (user) {
      client.join(user.id);
    } else {
      client.disconnect(true);
    }
  }
  @WebSocketServer() public server!: Server;
}

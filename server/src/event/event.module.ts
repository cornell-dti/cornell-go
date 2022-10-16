import { forwardRef, Module } from '@nestjs/common';
import { EventService } from './event.service';
import { EventGateway } from './event.gateway';
import { UserModule } from '../user/user.module';
import { ClientModule } from 'src/client/client.module';
import { AuthModule } from 'src/auth/auth.module';

@Module({
  imports: [forwardRef(() => UserModule), UserModule, ClientModule, AuthModule],
  providers: [EventService, EventGateway],
  exports: [EventService, EventGateway],
})
export class EventModule {}

import { Module } from '@nestjs/common';
import { AuthModule } from 'src/auth/auth.module';
import { AdminGateway } from './admin.gateway';
import { AdminService } from './admin.service';
import { AdminCallbackService } from './admin-callback/admin-callback.service';
import { ClientModule } from 'src/client/client.module';

@Module({
  imports: [AuthModule, ClientModule],
  providers: [AdminGateway, AdminService, AdminCallbackService],
})
export class AdminModule {}

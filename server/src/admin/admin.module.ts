import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from 'src/auth/auth.module';
import { AdminGateway } from './admin.gateway';
import { AdminService } from './admin.service';
import { AdminCallbackService } from './admin-callback/admin-callback.service';
import { ClientModule } from 'src/client/client.module';
import { UserModule } from 'src/user/user.module';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [AuthModule, ClientModule, UserModule, PrismaModule],
  providers: [AdminGateway, AdminService, AdminCallbackService],
  controllers: [],
})
export class AdminModule {}

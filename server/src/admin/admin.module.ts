import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from 'src/auth/auth.module';
import { ClientModule } from 'src/client/client.module';
import { UserModule } from 'src/user/user.module';
import { GroupModule } from 'src/group/group.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AdminCallbackService } from './admin-callback/admin-callback.service';
import { AdminGateway } from './admin.gateway';
import { AdminService } from './admin.service';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    ClientModule,
    UserModule,
    GroupModule,
    PrismaModule,
  ],
  providers: [AdminGateway, AdminService, AdminCallbackService],
  controllers: [],
})
export class AdminModule {}

import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from 'src/auth/auth.module';
import { ClientModule } from 'src/client/client.module';
import { UserModule } from 'src/user/user.module';
import { GroupModule } from 'src/group/group.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AdminCallbackService } from './admin-callback/admin-callback.service';
import { AdminGateway } from './admin.gateway';
import { AdminService } from './admin.service';
import { OrganizationModule } from 'src/organization/organization.module';
import { EventModule } from 'src/event/event.module';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    ClientModule,
    UserModule,
    GroupModule,
    OrganizationModule,
    EventModule,
    PrismaModule,
  ],
  providers: [AdminGateway, AdminService, AdminCallbackService],
  controllers: [],
})
export class AdminModule { }

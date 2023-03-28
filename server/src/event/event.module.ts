import { forwardRef, Module } from '@nestjs/common';
import { ClientModule } from 'src/client/client.module';
import { UserGateway } from 'src/user/user.gateway';
import { AuthModule } from '../auth/auth.module';
import { OrganizationModule } from '../organization/organization.module';
import { PrismaModule } from '../prisma/prisma.module';
import { EventGateway } from './event.gateway';
import { EventService } from './event.service';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    ClientModule,
    PrismaModule,
    OrganizationModule,
  ],
  providers: [EventService, EventGateway],
  exports: [EventService, EventGateway],
})
export class EventModule {}

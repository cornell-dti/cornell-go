import { forwardRef, Module } from '@nestjs/common';
import { ClientModule } from '../client/client.module';
import { UserGateway } from '../user/user.gateway';
import { AuthModule } from '../auth/auth.module';
import { OrganizationModule } from '../organization/organization.module';
import { PrismaModule } from '../prisma/prisma.module';
import { EventGateway } from './event.gateway';
import { EventService } from './event.service';
import { CaslModule } from '../casl/casl.module';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    forwardRef(() => CaslModule),
    ClientModule,
    PrismaModule,
    OrganizationModule,
  ],
  providers: [EventService, EventGateway],
  exports: [EventService, EventGateway],
})
export class EventModule {}

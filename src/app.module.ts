import { Module } from '@nestjs/common';
import { EventsModule } from './events/events.module';
import { GroupsModule } from './groups/groups.module';
import { PlacesModule } from './places/places.module';
import { UsersModule } from './users/users.module';
import { AdminModule } from './admin/admin.module';
import { LeadersModule } from './leaders/leaders.module';
import { AuthModule } from './auth/auth.module';

@Module({
  imports: [EventsModule, GroupsModule, PlacesModule, UsersModule, AdminModule, LeadersModule, AuthModule],
  controllers: [],
  providers: [],
})
export class AppModule {}

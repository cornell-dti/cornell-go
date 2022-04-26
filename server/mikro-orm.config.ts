import { TsMorphMetadataProvider } from '@mikro-orm/reflection';
import { RestrictionGroup } from './src/model/restriction-group.entity';
import { Challenge } from './src/model/challenge.entity';
import { EventBase } from './src/model/event-base.entity';
import { EventReward } from './src/model/event-reward.entity';
import { EventTracker } from './src/model/event-tracker.entity';
import { Group } from './src/model/group.entity';
import { PrevChallenge } from './src/model/prev-challenge.entity';
import { SessionLogEntry } from './src/model/session-log-entry.entity';
import { User } from './src/model/user.entity';

export default {
  type: 'postgresql',
  entities: [
    Challenge,
    EventBase,
    EventReward,
    EventTracker,
    Group,
    PrevChallenge,
    SessionLogEntry,
    User,
    RestrictionGroup,
  ],
  allowGlobalContext: true,
  name: 'CornellGO PostgreSQL DB',
  clientUrl: 'postgresql://postgres:test@localhost:5432/postgres',
  forceUtcTimezone: true,
  validate: true,
  strict: true,
  debug: true,
  persistOnCreate: true,
  registerRequestContext: false,
  metadataProvider: TsMorphMetadataProvider,
  migrations: {
    path: 'dist/migrations',
    pathTs: 'src/migrations',
    disableForeignKeys: false,
  },
  schemaGenerator: {
    disableForeignKeys: false,
  },
};

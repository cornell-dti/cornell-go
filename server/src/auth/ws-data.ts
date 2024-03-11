import { User } from '@prisma/client';
import { AppAbility } from '../casl/casl-ability.factory';

export type WsData = { _authenticatedUserEntity: User; _ability: AppAbility };

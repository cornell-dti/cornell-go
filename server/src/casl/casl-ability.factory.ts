import { PermittedFieldsOptions, permittedFieldsOf } from '@casl/ability/extra';
import { Action } from './action.enum';
import { AbilityBuilder, ExtractSubjectType, PureAbility } from '@casl/ability';
import { PrismaQuery, Subjects, createPrismaAbility } from '@casl/prisma';
import { Injectable } from '@nestjs/common';
import {
  Achievement,
  AchievementTracker,
  Challenge,
  EventBase,
  EventTracker,
  Group,
  Organization,
  PrevChallenge,
  SessionLogEntry,
  User,
} from '@prisma/client';

export type SubjectTypes = {
  User: User;
  Group: Group;
  Organization: Organization;
  EventTracker: EventTracker;
  Challenge: Challenge;
  EventBase: EventBase;
  PrevChallenge: PrevChallenge;
  SessionLogEntry: SessionLogEntry;
  Achievement: Achievement;
  AchievementTracker: AchievementTracker;
};

export type AppAbility = PureAbility<
  [string, Subjects<SubjectTypes> | 'all'],
  PrismaQuery
>;

@Injectable()
export class CaslAbilityFactory {
  async filterInaccessible(
    data: any,
    subject: Subjects<SubjectTypes>,
    ability: AppAbility,
    action: Action,
  ) {
    const fieldList = Object.keys(data);
    const options: PermittedFieldsOptions<AppAbility> = {
      fieldsFrom: rule => rule.fields || fieldList,
    };

    const permitted = permittedFieldsOf(ability, action, subject, options);
    const newObj: any = {};
    for (const permittedField of permitted) {
      newObj[permittedField] = data[permittedField];
    }

    return newObj;
  }

  createForUser(user: User) {
    const { can, cannot, build } = new AbilityBuilder<AppAbility>(
      createPrismaAbility,
    );

    if (user.isBanned) {
      // Go no further if banned
      cannot('all', 'all');
      return build();
    }

    if (user.administrator || process.env.TESTING_UNIT == 'true') {
      // full access to everything
      can(Action.Manage, 'all');
      return build();
    }

    can(Action.Manage, 'User', ['enrollmentType', 'username', 'year'], {
      id: user.id,
    });

    can(
      Action.Read,
      'User',
      ['email', 'groupId', 'id', 'score', 'trackedEvents', 'favorites'],
      {
        id: user.id,
      },
    );

    can(Action.Read, 'Achievement');

    can(Action.Read, 'AchievementTracker', undefined, { userId: user.id });

    can(Action.Read, 'Challenge', undefined, {
      linkedEvent: { usedIn: { some: { members: { some: { id: user.id } } } } },
    });

    can(Action.Manage, 'Challenge', undefined, {
      linkedEvent: {
        usedIn: { some: { managers: { some: { id: user.id } } } },
      },
    });

    can(Action.Read, 'EventBase', undefined, {
      usedIn: { some: { members: { some: { id: user.id } } } },
    });

    can(Action.Manage, 'EventBase', undefined, {
      usedIn: { some: { managers: { some: { id: user.id } } } },
    });

    can(Action.Read, 'EventTracker', undefined, {
      OR: [
        { userId: user.id },
        {
          event: { usedIn: { some: { managers: { some: { id: user.id } } } } },
        },
      ],
    });

    can(Action.Read, 'Group', undefined, {
      members: { some: { id: user.id } },
    });

    can(Action.Update, 'Group', undefined, {
      hostId: user.id,
    });

    can(Action.Read, 'Organization', undefined, {
      members: { some: { id: user.id } },
    });

    // These come from DTO
    cannot(Action.Read, 'Organization', ['members', 'managers']);

    can(Action.Manage, 'Organization', undefined, {
      managers: { some: { id: user.id } },
    });

    can(Action.Read, 'PrevChallenge', undefined, {
      OR: [
        { userId: user.id },
        {
          challenge: {
            linkedEvent: {
              usedIn: { some: { managers: { some: { id: user.id } } } },
            },
          },
        },
      ],
    });

    return build();
  }
}

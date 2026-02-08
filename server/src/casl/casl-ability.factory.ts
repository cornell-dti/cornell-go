import { Action } from './action.enum';
import {
  AbilityBuilder,
  ExtractSubjectType,
  PureAbility,
  subject,
} from '@casl/ability';
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
  QuizQuestion,
  QuizAnswer,
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
  QuizQuestion: QuizQuestion;
  QuizAnswer: QuizAnswer;
};

export type AppAbility = PureAbility<
  [string, Subjects<SubjectTypes> | 'all'],
  PrismaQuery
>;

@Injectable()
export class CaslAbilityFactory {
  async filterInaccessible<TObj extends {}>(
    id: string,
    data: TObj,
    subj: ExtractSubjectType<Subjects<SubjectTypes>>,
    ability: AppAbility,
    action: Action,
    prismaStore: {
      count: (...args: any[]) => Promise<number>;
    },
  ): Promise<Partial<TObj>> {
    // TODO: optimize this function to minimize database hits (maybe a cache?)
    // Potentially the following info inside the AppAbility (should not be too hard)

    const newObj: any = {};
    let fields: string[] = Object.keys(data);

    const fieldSet = new Set<string>();

    for (const field of fields) {
      const rules = ability
        .rulesFor(action, subj, field)
        .sort((a, b) => b.priority - a.priority); // Higher priority first

      for (const rule of rules) {
        // Skip when it already has and it isn't a negative rule
        // and when it does not have but it's a positive rule
        // to save on database queries
        if (fieldSet.has(field) === !rule.inverted) continue;

        const prismaCond = {
          where: {
            AND: [{ id }, rule.conditions],
          },
        };

        if (!rule.conditions || (await prismaStore.count(prismaCond)) > 0) {
          if (rule.inverted) {
            fieldSet.delete(field);
          } else {
            fieldSet.add(field);
          }
        }
      }
    }

    for (const field of fieldSet) {
      newObj[field] = (data as any)[field];
    }

    return newObj;
  }

  createFull() {
    const { can, cannot, build } = new AbilityBuilder<AppAbility>(
      createPrismaAbility,
    );

    can(Action.Manage, 'all');

    return build();
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

    if (user.administrator) {
      // full access to everything
      can(Action.Manage, 'all');
      return build();
    }

    can(
      Action.Manage,
      'User',
      ['enrollmentType', 'username', 'college', 'major', 'year'],
      {
        id: user.id,
      },
    );

    can(
      Action.Read,
      'User',
      [
        'email',
        'groupId',
        'id',
        'score',
        'trackedEvents',
        'favorites',
        'authType',
        'hasCompletedOnboarding',
      ],
      {
        id: user.id,
      },
    );

    can(Action.Read, 'User', ['username'], {
      groupId: user.groupId,
    });

    can(Action.Read, 'Achievement');

    can(Action.Read, 'AchievementTracker', { userId: user.id });

    can(Action.Manage, 'Achievement', {
      organizations: { some: { managers: { some: { id: user.id } } } },
    });

    // Read challenges that belong to events you're allowed to access
    // And you must have completed them or are in the process
    can(Action.Read, 'Challenge', undefined, {
      linkedEvent: {
        usedIn: { some: { members: { some: { id: user.id } } } },
      },
    });

    cannot(Action.Read, 'Challenge', ['name'], {
      AND: [
        {
          completions: {
            none: { userId: user.id },
          },
        },
      ],
    });

    const latlongNames = [
      'latitude',
      'longitude',
      'latitudeF',
      'longitudeF',
      'lat',
      'long',
      'latF',
      'longF',
    ];

    cannot(Action.Read, 'Challenge', latlongNames, {
      activeTrackers: {
        none: {
          user: { id: user.id },
          event: {
            activeGroups: { some: { members: { some: { id: user.id } } } },
          },
        },
      },
      eventIndex: { not: 0 },
    });

    can(Action.Manage, 'Challenge', {
      linkedEvent: {
        usedIn: { some: { managers: { some: { id: user.id } } } },
      },
    });

    can(Action.Read, 'EventBase', {
      usedIn: { some: { members: { some: { id: user.id } } } },
      indexable: true,
    });

    can(Action.Manage, 'EventBase', {
      usedIn: { some: { managers: { some: { id: user.id } } } },
    });

    can(Action.Read, 'EventTracker', {
      OR: [
        { userId: user.id },
        {
          event: { usedIn: { some: { managers: { some: { id: user.id } } } } },
        },
      ],
    });

    can(Action.Read, 'Group', {
      members: { some: { id: user.id } },
    });

    can(Action.Update, 'Group', {
      hostId: user.id,
    });

    can(Action.Read, 'Organization', {
      members: { some: { id: user.id } },
    });

    // These come from DTO
    cannot(Action.Read, 'Organization', ['members', 'managers']);

    can(Action.Read, 'Organization', ['members', 'managers'], {
      managers: { some: { id: user.id } },
    });

    can(Action.Update, 'Organization', {
      managers: { some: { id: user.id } },
    });

    can(Action.Read, 'PrevChallenge', {
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

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
      for (const rule of ability.rulesFor(action, subj, field)) {
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

    can(Action.Read, 'User', ['username'], {
      groupId: user.groupId,
    });

    can(Action.Read, 'Achievement');

    can(Action.Read, 'AchievementTracker', { userId: user.id });

    can(Action.Read, 'Challenge', {
      AND: [
        {
          linkedEvent: {
            usedIn: { some: { members: { some: { id: user.id } } } },
          },
        },
        {
          OR: [
            {
              completions: {
                some: { userId: user.id },
              },
            },
            {
              activeTrackers: {
                some: { userId: user.id },
              },
            },
          ],
        },
      ],
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

    cannot(
      Action.Read,
      'Challenge',
      ['latitude', 'longitude', 'latitudeF', 'longitudeF'],
      {
        // names come from DTO
        // hide lat long from users that do not have an active tracker which is their current event
        activeTrackers: {
          none: {
            user: { id: user.id },
            event: {
              activeGroups: { some: { members: { some: { id: user.id } } } },
            },
          },
        },
      },
    );

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

    can(Action.Manage, 'Organization', {
      managers: { some: { id: user.id } },
    });

    cannot(Action.Delete, 'Organization');

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

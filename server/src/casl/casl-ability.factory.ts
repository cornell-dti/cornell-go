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
  async filterInaccessible<TObj, TPrismaStore>(
    id: string,
    data: TObj,
    subject: ExtractSubjectType<Subjects<SubjectTypes>>,
    ability: AppAbility,
    action: Action,
    prismaStore: {
      count: (...args: any[]) => Promise<number>;
    },
  ): Promise<Partial<TObj>> {
    // TODO: optimize this function to minimize database hits (maybe a cache?)
    // Potentially the following info inside the AppAbility (should not be too hard)

    if (ability.can(action, subject)) return data;

    const newObj: any = {};
    let remainingFields: string[] = [];

    for (const field in data) {
      if (ability.can(action, subject, field)) {
        newObj[field] = (data as any)[field];
      } else {
        remainingFields.push(field);
      }
    }

    let positiveFieldMap = new Map<Object, string[]>(); // These can be added
    let negativeFieldMap = new Map<Object, string[]>(); // These must be removed

    for (const field of remainingFields) {
      for (const rule of ability.rulesFor(action, subject, field)) {
        const cond = rule.conditions;

        if (rule.inverted) {
          if (!cond) {
            delete newObj[field];
          } else {
            if (!negativeFieldMap.has(cond)) negativeFieldMap.set(cond, []);
            negativeFieldMap.get(cond)!.push(field);
          }
        } else {
          if (!cond) {
            continue;
          }

          if (!positiveFieldMap.has(cond)) positiveFieldMap.set(cond, []);
          positiveFieldMap.get(cond)!.push(field);
        }
      }
    }

    const fieldSet = new Set<string>();

    for (const [cond, fields] of positiveFieldMap.entries()) {
      const prismaCond = {
        where: {
          AND: [{ id }, cond],
        },
      };

      if ((await prismaStore.count(prismaCond)) > 0) {
        fields.forEach(v => fieldSet.add(v));
      }
    }

    for (const [cond, fields] of negativeFieldMap.entries()) {
      const prismaCond = {
        where: {
          AND: [{ id }, cond],
        },
      };

      if ((await prismaStore.count(prismaCond)) > 0) {
        fields.forEach(v => fieldSet.delete(v));
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
      linkedEvent: { usedIn: { some: { members: { some: { id: user.id } } } } },
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

    can(Action.Manage, 'Organization', {
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

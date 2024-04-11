import { Injectable } from '@nestjs/common';
import {
  EventBase,
  Organization,
  DifficultyMode,
  TimeLimitationType,
  OrganizationSpecialUsage,
  User,
  LocationType,
} from '@prisma/client';
import { ClientService } from '../client/client.service';
import { v4 } from 'uuid';
import { PrismaService } from '../prisma/prisma.service';
import { OrganizationDto, UpdateOrganizationDataDto } from './organization.dto';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';
import { accessibleBy } from '@casl/prisma';

export const defaultEventData = {
  name: 'Default Event',
  description: 'Default Event',
  requiredMembers: 1,
  difficulty: DifficultyMode.NORMAL,
  timeLimitation: TimeLimitationType.PERPETUAL,
  indexable: true,
  endTime: new Date('2060'),
  latitude: 42.44755580740012,
  longitude: -76.48504614830019,
};

export const defaultChallengeData = {
  eventIndex: 0,
  name: 'Default Challenge',
  location: LocationType.ARTS_QUAD,
  description: 'McGraw Tower',
  points: 50,
  imageUrl:
    'https://upload.wikimedia.org/wikipedia/commons/5/5f/CentralAvenueCornell2.jpg',
  latitude: 42.44755580740012,
  longitude: -76.48504614830019,
  awardingRadius: 50,
  closeRadius: 100,
};

@Injectable()
export class OrganizationService {
  constructor(
    private prisma: PrismaService,
    private clientService: ClientService,
    private abilityFactory: CaslAbilityFactory,
  ) {}

  // TODO: maybe move this to challenge.service in the future?
  async makeDefaultChallenge() {
    return await this.prisma.challenge.create({
      data: {
        ...defaultChallengeData,
      },
    });
  }

  // TODO: maybe move this to event.service in the future?
  async makeDefaultEvent() {
    const chal = await this.makeDefaultChallenge();

    const ev = await this.prisma.eventBase.create({
      data: {
        ...defaultEventData,
        challenges: { connect: { id: chal.id } },
      },
    });

    return ev;
  }

  async getDefaultEvent(org: Organization): Promise<EventBase> {
    return await this.prisma.eventBase.findFirstOrThrow({
      where: { usedIn: { some: { id: org.id } } },
    });
  }

  /** Returns (and creates if does not exist) the default organization for
   * this usage */
  async getDefaultOrganization(
    usage: OrganizationSpecialUsage,
  ): Promise<Organization> {
    if (usage === OrganizationSpecialUsage.NONE) {
      throw 'Default impossible for NONE';
    }

    let defaultOrg = await this.prisma.organization.findFirst({
      where: { specialUsage: usage },
    });

    if (defaultOrg === null) {
      const ev = await this.makeDefaultEvent();

      defaultOrg = await this.prisma.organization.create({
        data: {
          name:
            usage === OrganizationSpecialUsage.CORNELL_LOGIN
              ? 'Cornell Organization'
              : 'Everyone Organization',
          specialUsage: usage,
          accessCode: this.genAccessCode(),
          events: { connect: { id: ev.id } },
        },
      });
    }

    return defaultOrg;
  }

  async getOrganizationsForUser(user: User, admin: boolean) {
    return await this.prisma.organization.findMany({
      where: admin
        ? { managers: { some: { id: user.id } } }
        : { members: { some: { id: user.id } } },
    });
  }

  async getOrganizationById(id: string) {
    return await this.prisma.organization.findFirstOrThrow({ where: { id } });
  }

  async getOrganizationByCode(accessCode: string) {
    return await this.prisma.organization.findFirstOrThrow({
      where: { accessCode },
    });
  }

  async dtoForOrganization(
    organization: Organization,
  ): Promise<OrganizationDto> {
    const org = this.prisma.organization.findUniqueOrThrow({
      where: { id: organization.id },
    });

    return {
      id: organization.id,
      name: organization.name,
      members: (await org.members({ select: { id: true } })).map(e => e.id),
      events: (await org.events({ select: { id: true } })).map(e => e.id),
      managers: (await org.managers({ select: { id: true } })).map(e => e.id),
      accessCode: organization.accessCode,
    };
  }

  async emitUpdateOrganizationData(
    organization: Organization,
    deleted: boolean,
    target?: User,
  ) {
    const dto: UpdateOrganizationDataDto = {
      organization: deleted
        ? { id: organization.id }
        : await this.dtoForOrganization(organization),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateOrganizationData',
      target?.id ?? organization.id,
      dto,
      {
        id: organization.id,
        subject: 'Organization',
        dtoField: 'organization',
        prismaStore: this.prisma.organization,
      },
    );
  }

  private genAccessCode() {
    return Math.floor(Math.random() * 0xffffff).toString(16);
  }

  /** Update/insert a organization group */
  async upsertOrganizationFromDto(
    ability: AppAbility,
    organization: OrganizationDto,
  ) {
    let org = await this.prisma.organization.findFirst({
      where: { id: organization.id },
    });

    const assignData = {
      name: organization.name,
      members: {
        connect: organization.members?.map(id => ({ id })),
      },
      events: {
        connect: organization.events?.map(id => ({ id })),
      },
      specialUsage: OrganizationSpecialUsage.NONE,
    };

    if (
      org &&
      (await this.prisma.organization.findFirst({
        select: { id: true },
        where: { AND: [accessibleBy(ability, Action.Update).Organization] },
      }))
    ) {
      const updateData = await this.abilityFactory.filterInaccessible(
        org.id,
        assignData,
        'Organization',
        ability,
        Action.Update,
        this.prisma.organization,
      );

      org = await this.prisma.organization.update({
        where: { id: org.id },
        data: updateData,
      });
    } else if (!org && ability.can(Action.Create, 'Organization')) {
      const data = {
        ...assignData,
        name: assignData.name ?? 'New organization',
        accessCode: Math.floor(Math.random() * 0xffffff).toString(16),
      };

      org = await this.prisma.organization.create({
        data,
      });

      console.log(`Created organization ${org.id}`);
    }

    return org;
  }

  async addAllAdmins(org: Organization) {
    const users = await this.prisma.user.findMany({
      where: { administrator: true },
    });

    for (const user of users) {
      this.clientService.subscribe(user, org.id);
    }
  }

  async removeOrganization(ability: AppAbility, id: string) {
    if (
      await this.prisma.organization.findFirst({
        where: {
          AND: [{ id }, accessibleBy(ability, Action.Delete).Organization],
        },
      })
    ) {
      await this.prisma.organization.delete({
        where: { id },
      });

      console.log(`Deleted organization ${id}`);
    }
  }

  async ensureFullAccessIfNeeded(potentialAdmin: User) {
    if (potentialAdmin.administrator) {
      const orgs = await this.prisma.organization.findMany({
        where: { managers: { none: { id: potentialAdmin.id } } },
        select: { id: true },
      });

      for (const { id } of orgs) {
        await this.prisma.user.update({
          where: { id: potentialAdmin.id },
          data: {
            managerOf: { connect: { id } },
            memberOf: { connect: { id } },
          },
        });
      }
    }
  }

  async addManager(
    ability: AppAbility,
    potentialManagerEmail: string,
    organizationId: string,
  ) {
    const org = await this.prisma.organization.findFirst({
      where: {
        AND: [
          accessibleBy(ability, Action.Manage).Organization,
          { id: organizationId },
        ],
      },
    });

    const potentialManager = await this.prisma.user.findFirst({
      where: { email: potentialManagerEmail },
    });

    if (!potentialManager || !org) {
      return false;
    }

    await this.prisma.organization.update({
      where: { id: org.id },
      data: {
        managers: { connect: { id: potentialManager.id } },
        members: { connect: { id: potentialManager.id } },
      },
    });

    await this.prisma.user.update({
      where: { id: potentialManager.id },
      data: { managerOf: { connect: { id: org.id } } },
    });

    console.log(`Manager ${potentialManagerEmail} Added`);

    return true;
  }

  async joinOrganization(user: User, code: string) {
    const org = await this.prisma.organization.findFirstOrThrow({
      where: { accessCode: code },
    });

    await this.prisma.organization.update({
      where: { id: org.id },
      data: { members: { connect: { id: user.id } } },
    });

    await this.prisma.user.update({
      where: { id: user.id },
      data: { memberOf: { connect: { id: org.id } } },
    });
  }
}

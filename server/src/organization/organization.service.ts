import { Injectable } from '@nestjs/common';
import {
  EventBase,
  EventRewardType,
  Organization,
  OrganizationSpecialUsage,
  User,
} from '@prisma/client';
import { ClientService } from 'src/client/client.service';
import { v4 } from 'uuid';
import { PrismaService } from '../prisma/prisma.service';
import { OrganizationDto, UpdateOrganizationDataDto } from './organization.dto';

export const defaultEventData = {
  name: 'Default Event',
  description: 'Default Event',
  requiredMembers: 1,
  minimumScore: 1,
  rewardType: EventRewardType.PERPETUAL,
  indexable: false,
  endTime: new Date('2060'),
};

export const defaultChallengeData = {
  eventIndex: 0,
  name: 'Default Challenge',
  description: 'McGraw Tower',
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
  ) {
    this.getDefaultOrganization(OrganizationSpecialUsage.CORNELL_LOGIN);
    this.getDefaultOrganization(OrganizationSpecialUsage.DEVICE_LOGIN);
  }

  async makeDefaultEvent() {
    const chal = await this.prisma.challenge.create({
      data: {
        ...defaultChallengeData,
      },
    });

    const ev = await this.prisma.eventBase.create({
      data: {
        ...defaultEventData,
        defaultChallengeId: chal.id,
        challenges: { connect: { id: chal.id } },
      },
    });

    return ev;
  }

  /** Returns (and creates if does not exist) the default organization for
   * this usage */
  async getDefaultOrganization(
    usage: OrganizationSpecialUsage,
  ): Promise<Organization & { defaultEvent: EventBase }> {
    if (usage === OrganizationSpecialUsage.NONE) {
      throw 'Default impossible for NONE';
    }

    let defaultOrg = await this.prisma.organization.findFirst({
      where: { specialUsage: usage },
      include: { defaultEvent: true },
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
          defaultEventId: ev.id,
          accessCode: this.genAccessCode(),
          events: { connect: { id: ev.id } },
        },
        include: { defaultEvent: true },
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

  /** Gets the default event for the org using isDefault flag */
  async getDefaultEvent(
    org: Organization | { id: string },
  ): Promise<EventBase> {
    return (
      await this.prisma.organization.findFirstOrThrow({
        where: { id: org.id },
        include: { defaultEvent: true },
      })
    ).defaultEvent;
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
      defaultEventId: organization.defaultEventId,
      accessCode: organization.accessCode,
    };
  }

  async emitUpdateOrganizationData(
    organization: Organization,
    deleted: boolean,
    admin?: boolean,
    user?: User,
  ) {
    const dto: UpdateOrganizationDataDto = {
      organization: deleted
        ? organization.id
        : await this.dtoForOrganization(organization),
      deleted,
    };

    // Only admin data for now
    if (user) {
      await this.clientService.sendUpdate(
        'updateOrganizationData',
        user.id,
        true,
        dto,
      );
    } else {
      await this.clientService.sendUpdate(
        'updateOrganizationData',
        organization.id,
        true,
        dto,
      );
    }
  }

  async isManagerOf(
    org: Organization | { id: string },
    user: User | { id: string },
  ) {
    return !!(await this.prisma.organization.findFirst({
      where: { id: org.id, managers: { some: { id: user.id } } },
    }));
  }

  private genAccessCode() {
    return Math.floor(Math.random() * 0xffffff).toString(16);
  }

  /** Update/insert a organization group */
  async upsertOrganizationFromDto(organization: OrganizationDto) {
    const exists =
      (await this.prisma.organization.count({
        where: { id: organization.id },
      })) > 0;

    return await this.prisma.organization.upsert({
      where: { id: organization.id },
      create: {
        name: organization.name,
        accessCode: Math.floor(Math.random() * 0xffffff).toString(16),
        members: {
          connect: organization.members.map(id => ({ id })),
        },
        events: {
          connect: organization.events.map(id => ({ id })),
        },
        defaultEvent: {
          connect: { id: exists ? '' : (await this.makeDefaultEvent()).id },
        },
        specialUsage: 'NONE',
      },
      update: {
        members: {
          set: organization.members.map(id => ({ id })),
        },
        events: {
          set: organization.events
            .map(id => ({ id }))
            .concat({ id: organization.defaultEventId }),
        },
      },
    });
  }

  async addAllAdmins(org: Organization) {
    const users = await this.prisma.user.findMany({
      where: { administrator: true },
    });

    for (const user of users) {
      this.clientService.subscribe(user, org.id, true);
    }
  }

  async removeOrganization(id: string) {
    await this.prisma.organization.delete({
      where: { id },
    });
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
          },
        });
      }
    }
  }

  async addManager(
    manager: User,
    potentialManagerEmail: string,
    organizationId: string,
  ) {
    const org = await this.prisma.organization.findFirstOrThrow({
      where: { id: organizationId },
    });

    if ((await this.isManagerOf(manager, org)) || manager.administrator) {
      const potentialManager = await this.prisma.user.findFirstOrThrow({
        where: { email: potentialManagerEmail },
      });
      await this.prisma.organization.update({
        where: { id: org.id },
        data: { managers: { connect: { id: potentialManager.id } } },
      });

      await this.prisma.user.update({
        where: { id: potentialManager.id },
        data: { managerOf: { connect: { id: org.id } } },
      });
      console.log('Manager Added');
    }
  }

  async joinOrganization(user: User, code: string) {
    const org = await this.prisma.organization.findFirstOrThrow({
      where: { accessCode: code },
    });

    console.log(org.id);
    console.log(user.id);
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

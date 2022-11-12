import { Injectable } from '@nestjs/common';
import {
  EventBase,
  EventRewardType,
  Organization,
  OrganizationSpecialUsage,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class OrganizationService {
  constructor(private prisma: PrismaService) {}

  private async makeDefaultEvent() {
    return await this.prisma.eventBase.create({
      data: {
        name: 'Default Event',
        description: 'Default Event',
        requiredMembers: 1,
        minimumScore: 1,
        skippingEnabled: true,
        isDefault: true,
        rewardType: EventRewardType.PERPETUAL,
        indexable: false,
        endTime: new Date('2060'),
        challenges: {
          create: {
            eventIndex: 0,
            name: 'New challenge',
            description: 'McGraw Tower',
            imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/5/5f/CentralAvenueCornell2.jpg',
            latitude: 42.44755580740012,
            longitude: -76.48504614830019,
            awardingRadius: 50,
            closeRadius: 100,
          },
        },
      },
    });
  }

  /** Returns (and creates if does not exist) the default organization for
   * this usage */
  async getDefaultOrganization(
    usage: OrganizationSpecialUsage,
  ): Promise<Organization & { allowedEvents: EventBase[] }> {
    let defaultOrg = await this.prisma.organization.findFirst({
      where: { isDefault: true },
      include: { allowedEvents: true },
    });

    if (defaultOrg === null) {
      let defaultEvent = await this.prisma.eventBase.findFirst({
        where: { isDefault: true },
      });
      if (defaultEvent === null) {
        defaultEvent = await this.makeDefaultEvent();
      }
      defaultOrg = await this.prisma.organization.create({
        data: {
          name: 'Default Organization',
          displayName: 'Default Organization',
          isDefault: true,
          canEditUsername: true, // can we allow anyone to edit username?
          specialUsage: usage,
          allowedEvents: {
            connect: {
              id: defaultEvent.id,
            },
          },
        },
        include: { allowedEvents: true },
      });
    }

    return defaultOrg;
  }

  /** Gets the default event for the org using isDefault flag */
  async getDefaultEvent(
    org: Organization | { id: string },
  ): Promise<EventBase> {
    let defaultOrgEvents = (
      await this.prisma.organization.findFirstOrThrow({
        where: { id: org.id },
        include: { allowedEvents: true },
      })
    ).allowedEvents;

    return await this.prisma.eventBase.findFirstOrThrow({
      where: {
        id: { in: defaultOrgEvents.map(event => event.id) },
        isDefault: true,
      },
    });
  }
}

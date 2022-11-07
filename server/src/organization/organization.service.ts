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
  constructor(private prisma: PrismaService) { }

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

  async getDefaultOrganization(
    usage: OrganizationSpecialUsage,
  ): Promise<Organization & { defaultEvent: EventBase }> {
    // TODO: get (and create if does not exist) the default organization for this usage

    throw 'Unimplemented!';
  }

  async getDefaultEvent(
    group: Organization | { id: string },
  ): Promise<EventBase> {
    // TODO: get the default event for the org. using isDefault flag, or the defaultEvent field once implemented

    throw 'Unimplemented!';
  }
}

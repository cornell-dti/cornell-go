import { UseGuards } from '@nestjs/common/decorators';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { CallingUser } from '../auth/calling-user.decorator';
import { UserGuard } from '../auth/jwt-auth.guard';
import { ClientService } from '../client/client.service';
import {
  OrganizationDto,
  RequestOrganizationDataDto,
  UpdateOrganizationDataDto,
} from './organization.dto';
import { OrganizationService } from './organization.service';
import { PoliciesGuard } from '../casl/policy.guard';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { UserAbility } from '../casl/user-ability.decorator';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class OrganizationGateway {
  constructor(
    private clientService: ClientService,
    private orgService: OrganizationService,
    private abilityFactory: CaslAbilityFactory,
  ) {}

  /**
   * Requests organization based on RequestOrganizationDataDto. Subscribes and emits the requested information
   * @param user The calling user
   * @param data The data to be requested
   */
  @SubscribeMessage('requestOrganizationData')
  async requestOrganizationData(
    @CallingUser() user: User,
    @MessageBody() data: RequestOrganizationDataDto,
  ) {
    await this.orgService.ensureFullAccessIfNeeded(user);

    const orgs = await this.orgService.getOrganizationsForUser(
      user,
      data.admin,
    );

    for (const org of orgs) {
      await this.orgService.emitUpdateOrganizationData(org, false, user);
    }
  }

  /**
   * Updates organization based on UpdateOrganizationDataDto. Subscribes and emits data
   * @param user The calling user
   * @param data The data to be updated
   * @returns Emits update organization
   */
  @SubscribeMessage('updateOrganizationData')
  async updateOrganizationData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: UpdateOrganizationDataDto,
  ) {
    if (data.deleted) {
      const org = await this.orgService.getOrganizationById(
        data.organization.id,
      );

      await this.orgService.removeOrganization(ability, data.organization.id);
      await this.orgService.emitUpdateOrganizationData(org, true);
    } else {
      const org = await this.orgService.upsertOrganizationFromDto(
        ability,
        data.organization,
      );

      if (!org) {
        await this.clientService.emitErrorData(
          user,
          'Failed to upsert organization!',
        );
        return;
      }

      this.clientService.subscribe(user, org.id);
      await this.orgService.emitUpdateOrganizationData(org, false);
    }
  }
}

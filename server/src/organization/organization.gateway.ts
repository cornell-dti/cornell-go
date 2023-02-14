import { UseGuards } from '@nestjs/common/decorators';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { CallingUser } from 'src/auth/calling-user.decorator';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { ClientService } from 'src/client/client.service';
import {
  OrganizationDto,
  RequestOrganizationDataDto,
  UpdateOrganizationDataDto,
} from './organization.dto';
import { OrganizationService } from './organization.service';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class OrganizationGateway {
  constructor(
    private clientService: ClientService,
    private orgService: OrganizationService,
  ) {}

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
      this.clientService.subscribe(user, org.id, data.admin);
      await this.orgService.emitUpdateOrganizationData(
        org,
        false,
        data.admin,
        user,
      );
    }
  }

  @SubscribeMessage('updateOrganizationData')
  async updateOrganizationData(
    @CallingUser() user: User,
    @MessageBody() data: UpdateOrganizationDataDto,
  ) {
    if (!user.administrator) return;

    if (data.deleted) {
      const org = await this.orgService.getOrganizationById(
        data.organization as string,
      );

      await this.orgService.removeOrganization(data.organization as string);
      await this.orgService.emitUpdateOrganizationData(org, true);
    } else {
      const org_data = data.organization as OrganizationDto;

      const org = await this.orgService.upsertOrganizationFromDto(org_data);

      await this.orgService.addAllAdmins(org);
      if (org_data.manager_email !== '')
        await this.orgService.addManager(user, org_data.manager_email, org);
      await this.orgService.emitUpdateOrganizationData(org, false);
    }
  }
}

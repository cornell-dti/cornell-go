import { Inject, UseGuards } from '@nestjs/common/decorators';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WsException,
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
import { forwardRef } from '@nestjs/common';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class OrganizationGateway {
  constructor(
    private clientService: ClientService,
    private orgService: OrganizationService,
  ) { }

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
    if (!user.administrator) {
      await this.clientService.emitErrorData(user, 'User has no admin rights');
      return;
    }

    if (data.deleted) {
      const org = await this.orgService.getOrganizationById(
        data.organization as string,
      );

      await this.orgService.removeOrganization(data.organization as string);
      await this.orgService.emitUpdateOrganizationData(org, true);
    } else {
      const org = await this.orgService.upsertOrganizationFromDto(
        data.organization as OrganizationDto,
      );
      this.clientService.subscribe(user, org.id, true);
      await this.orgService.emitUpdateOrganizationData(org, false);
    }
  }

  @SubscribeMessage('addManager')
  async addManager(
    @CallingUser() user: User,
    @MessageBody() data: { email: string; organizationId: string },
  ) {
    if (!user.administrator) return;

    await this.orgService.addManager(user, data.email, data.organizationId);

    const org = await this.orgService.getOrganizationById(data.organizationId);
    await this.orgService.emitUpdateOrganizationData(org, false);

    /*
    const manager = await this.userService.byEmail(data.email);
    await this.userService.emitUpdateUserData(
      manager,
      false,
      false,
      true,
      user,
    );*/
  }

  @SubscribeMessage('joinOrganization')
  async joinOrganization(
    @CallingUser() user: User,
    @MessageBody() data: { accessCode: string },
  ) {
    await this.orgService.joinOrganization(user, data.accessCode);

    const org = await this.orgService.getOrganizationByCode(data.accessCode);
    await this.orgService.emitUpdateOrganizationData(org, false);

    //await this.userService.emitUpdateUserData(user, false, false, true);
  }
}

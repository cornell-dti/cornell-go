import { Inject, Injectable, forwardRef } from '@nestjs/common';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateErrorDto } from './client.dto';
import { ClientGateway } from './client.gateway';
import {
  AppAbility,
  CaslAbilityFactory,
  SubjectTypes,
} from '../casl/casl-ability.factory';
import { PermittedFieldsOptions, permittedFieldsOf } from '@casl/ability/extra';
import { Action } from '../casl/action.enum';
import { Subjects } from '@casl/prisma';
import { UpdateUserDataDto } from '../user/user.dto';
import { UpdateChallengeDataDto } from '../challenge/challenge.dto';
import {
  EventTrackerDto,
  UpdateEventDataDto,
  UpdateLeaderPositionDto,
  UpdateLeaderDataDto,
} from '../event/event.dto';
import { GroupInviteDto, UpdateGroupDataDto } from '../group/group.dto';
import { UpdateOrganizationDataDto } from '../organization/organization.dto';
import {
  AchievementTrackerDto,
  UpdateAchievementDataDto,
} from '../achievement/achievement.dto';
import {
  UpdateBearItemsDataDto,
  UpdatePurchaseResultDto,
  UpdateUserBearLoadoutDataDto,
  UpdateUserInventoryDataDto,
} from '../avatar/avatar.dto';
import { ExtractSubjectType } from '@casl/ability';

export type ClientApiDef = {
  updateUserData: UpdateUserDataDto;
  updateErrorData: UpdateErrorDto;
  updateChallengeData: UpdateChallengeDataDto;
  updateAchievementData: UpdateAchievementDataDto;
  updateAchievementTrackerData: AchievementTrackerDto;
  updateEventTrackerData: EventTrackerDto;
  updateEventData: UpdateEventDataDto;
  updateLeaderData: UpdateLeaderDataDto;
  groupInvitation: GroupInviteDto;
  updateGroupData: UpdateGroupDataDto;
  updateOrganizationData: UpdateOrganizationDataDto;
  updateLeaderPosition: UpdateLeaderPositionDto;
  updateBearItemsData: UpdateBearItemsDataDto;
  updateUserInventoryData: UpdateUserInventoryDataDto;
  updateUserBearLoadoutData: UpdateUserBearLoadoutDataDto;
  updatePurchaseResult: UpdatePurchaseResultDto;
};

@Injectable()
export class ClientService {
  constructor(
    private gateway: ClientGateway,
    private abilityFactory: CaslAbilityFactory,
    private prisma: PrismaService,
  ) { }

  public subscribe(user: User, resourceId: string) {
    if (process.env.TESTING_E2E === 'true') {
      return;
    }
    this.gateway.server.in(user.id).socketsJoin(resourceId);
  }

  public unsubscribe(user: User, resourceId: string) {
    if (process.env.TESTING_E2E === 'true') {
      return;
    }
    this.gateway.server.in(user.id).socketsLeave(resourceId);
  }

  public unsubscribeAll(resourceId: string) {
    if (process.env.TESTING_E2E === 'true') {
      return;
    }
    this.gateway.server.socketsLeave([resourceId]);
  }

  async emitErrorData(user: User, message: string) {
    const dto: UpdateErrorDto = {
      id: user.id,
      message,
    };

    await this.sendProtected('updateErrorData', user, dto);
  }

  async getAffectedUsers(target: string) {
    if (process.env.TESTING_E2E === 'true') {
      return [];
    }
    // Get list of targeted sockets
    const socks = await this.gateway.server.in(target).fetchSockets();

    // Find ids of all targeted users
    const userIds = socks.map(sock => sock.data['userId']);

    // Find all targeted users
    const users = await this.prisma.user.findMany({
      where: { id: { in: userIds } },
    });

    return users;
  }

  async sendEvent<TDto extends {}>(
    users: string[] | null,
    event: string,
    dto: TDto,
  ) {
    if (process.env.TESTING_E2E === 'true') {
      return;
    }

    if (users) this.gateway.server.to(users).emit(event, dto);
    else this.gateway.server.emit(event, dto);
  }

  async sendProtected<TDto extends {}>(
    event: keyof ClientApiDef,
    target: string | User | null,
    dto: ClientApiDef[typeof event] & TDto,
    resource?: {
      id: string;
      dtoField?: keyof TDto;
      subject: ExtractSubjectType<Subjects<SubjectTypes>>;
      prismaStore: {
        count: (...args: any[]) => Promise<number>;
      };
    },
  ) {
    if (!target) {
      this.sendEvent(null, event, dto);
      return;
    }

    const room = target instanceof Object ? 'user/' + target.id : target;
    if (!resource) {
      if (process.env.TESTING_E2E !== 'true') {
        this.gateway.server.to(room).emit(event, dto);
      }
    } else {
      if (process.env.TESTING_E2E !== 'true') {
        this.gateway.server.in(room).socketsJoin(resource.id);
      }
      // Find all targeted users
      const users = await this.getAffectedUsers(room);

      for (const user of users) {
        const ability = this.abilityFactory.createForUser(user);
        const accessibleObj = await this.abilityFactory.filterInaccessible(
          resource.id,
          resource.dtoField ? (dto as any)[resource.dtoField] : dto,
          resource.subject,
          ability,
          Action.Read,
          resource.prismaStore,
        );

        if (Object.keys(accessibleObj).length === 0) continue;

        if (resource.dtoField) {
          const newDto = {
            ...dto,
            [resource.dtoField]: accessibleObj,
          };
          await this.sendEvent(['user/' + user.id], event, newDto);
        } else {
          await this.sendEvent(['user/' + user.id], event, accessibleObj);
        }
      }
    }
  }
}

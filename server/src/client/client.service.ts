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
import { tokenOfHandshake } from '../auth/jwt-auth.guard';
import { PermittedFieldsOptions, permittedFieldsOf } from '@casl/ability/extra';
import { Action } from '../casl/action.enum';
import { ExtractSubjectType } from '@casl/ability';
import { Subjects } from '@casl/prisma';
import { AuthService } from '../auth/auth.service';

@Injectable()
export class ClientService {
  constructor(
    private gateway: ClientGateway,
    private abilityFactory: CaslAbilityFactory,
    private prisma: PrismaService,
  ) {}

  public subscribe(user: User, resourceId: string) {
    this.gateway.server.in(user.id).socketsJoin(resourceId);
  }

  public unsubscribe(user: User, resourceId: string) {
    this.gateway.server.in(user.id).socketsLeave(resourceId);
  }

  public unsubscribeAll(resourceId: string) {
    this.gateway.server.socketsLeave([resourceId]);
  }

  async emitErrorData(user: User, message: string) {
    const dto: UpdateErrorDto = {
      id: user.id,
      message,
    };
    await this.sendProtected('updateErrorData', user.id, dto);
  }

  async sendProtected<TDto extends {}>(
    event: string,
    target: string,
    dto: TDto,
    resourceId?: string,
    dtoSubject?: Subjects<SubjectTypes>,
  ) {
    if (resourceId) this.gateway.server.in(target).socketsJoin(resourceId);

    if (!dtoSubject) {
      this.gateway.server.to(target).emit(event, dto);
    } else {
      const fieldList = Object.keys(dto);
      const options: PermittedFieldsOptions<AppAbility> = {
        fieldsFrom: rule => rule.fields || fieldList,
      };
      // Get list of targeted sockets
      const socks = await this.gateway.server.in(target).fetchSockets();

      // Find ids of all targeted users
      const userIds = socks.map(sock => sock.data['userId']);

      // Find all targeted users
      const users = await this.prisma.user.findMany({
        where: { id: { in: userIds } },
      });

      // Map from sorted list of properties to a list of user ids
      const separatedDtos = new Map<string[], string[]>();

      for (const user of users) {
        const ability = this.abilityFactory.createForUser(user);
        const permittedFields = permittedFieldsOf(
          ability,
          Action.Read,
          dtoSubject,
          options,
        ).sort();

        // Add user to this batch (which contains exactly these properties)
        let userList = separatedDtos.get(permittedFields);
        if (!userList) {
          userList = [];
          separatedDtos.set(permittedFields, userList);
        }

        userList.push(user.id);
      }

      // Process all batches and send out DTO
      for (const [fields, users] of separatedDtos) {
        const partialDto = Object.fromEntries(
          Object.entries(dto).filter(([k, v]) => fields.includes(k)),
        );

        this.gateway.server.to(users).emit(event, partialDto);
      }
    }
  }
}

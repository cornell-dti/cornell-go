import { Injectable } from '@nestjs/common';
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

@Injectable()
export class ClientService {
  constructor(
    private gateway: ClientGateway,
    private abilityFactory: CaslAbilityFactory,
    private prisma: PrismaService,
  ) {}

  public sendUpdate<TDto>(
    event: string,
    resourceId: string,
    admin: boolean,
    dto: TDto,
  ) {
    this.gateway.server.to(resourceId).emit(event, dto);
  }

  public subscribe(user: User, resourceId: string, admin: boolean) {
    this.gateway.server.in(user.id).socketsJoin(resourceId);
  }

  public unsubscribe(user: User, resourceId: string, admin: boolean) {
    this.gateway.server.in(user.id).socketsLeave(resourceId);
  }

  public unsubscribeAll(resourceId: string) {
    this.gateway.server.socketsLeave([resourceId]);
  }

  async emitErrorData(user: User, message: string) {
    const dto: UpdateErrorDto = {
      message,
    };
    this.sendProtected('updateErrorData', user.id, dto);
  }

  async sendProtected<TDto extends {}>(
    event: string,
    target: string,
    dto: TDto,
    dtoSubject?: ExtractSubjectType<SubjectTypes>,
  ) {
    if (!dtoSubject) {
      this.gateway.server.to(target).emit(event, dto);
    } else {
      const fieldList = Object.keys(dto);
      const options: PermittedFieldsOptions<AppAbility> = {
        fieldsFrom: rule => rule.fields || fieldList,
      };
      // Get list of targeted sockets
      const socks = await this.gateway.server.in(target).fetchSockets();

      // Find auth tokens of all targeted users
      const tokens = socks
        .map(sock => tokenOfHandshake(sock.handshake))
        .filter(token => token) as string[];

      // Find all targeted users
      const users = await this.prisma.user.findMany({
        where: { authToken: { in: tokens } },
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

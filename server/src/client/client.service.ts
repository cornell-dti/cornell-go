import { Injectable } from '@nestjs/common';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateErrorDto } from './client.dto';
import { ClientGateway } from './client.gateway';
import { CaslAbilityFactory } from '../casl/casl-ability.factory';
import { tokenOfHandshake } from '../auth/jwt-auth.guard';

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

  async sendProtected<TDto, TResource>(
    event: string,
    target: string,
    dto: TDto,
    dtoSubject?: string,
  ) {
    if (!dtoSubject) {
      this.gateway.server.to(target).emit(event, dto);
    } else {
      const socks = await this.gateway.server.in(target).fetchSockets();

      const tokens = socks
        .map(sock => tokenOfHandshake(sock.handshake))
        .filter(token => token) as string[];

      const users = await this.prisma.user.findMany({
        where: { id: { in: tokens } },
      });

      const separatedDtos = new Map<string[], Partial<TDto>>();

      this.abilityFactory.createForUser();
    }
  }
}

import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { WsData } from '../auth/ws-data';

export const UserAbility = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    return ctx.switchToWs().getData<WsData>()._ability;
  },
);

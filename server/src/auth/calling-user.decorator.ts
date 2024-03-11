import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { WsData } from './ws-data';

export const CallingUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    return ctx.switchToWs().getData<WsData>()._authenticatedUserEntity;
  },
);

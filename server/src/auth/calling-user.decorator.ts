import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { User } from '../model/user.entity';

export const CallingUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    return ctx.switchToWs().getData<{ _authenticatedUserEntity: User }>();
  },
);

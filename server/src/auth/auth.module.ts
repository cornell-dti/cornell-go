import { forwardRef, Module } from '@nestjs/common';
import { GoogleController } from './google/google.controller';
import { AppleController } from './apple/apple.controller';
import { DeviceLoginController } from './device-login/device-login.controller';
import { AuthService } from './auth.service';
import { UserModule } from '../user/user.module';
import { JwtModule } from '@nestjs/jwt';
import { RefreshAccessController } from './refresh-access/refresh-access.controller';
import { UserGuard } from './jwt-auth.guard';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthGateway } from './auth.gateway';

@Module({
  imports: [
    forwardRef(() => UserModule),
    PrismaModule,
    JwtModule.register({
      secret: process.env.JWT_ACCESS_SECRET,
      signOptions: { expiresIn: process.env.JWT_ACCESS_EXPIRATION },
    }),
  ],
  controllers: [
    GoogleController,
    AppleController,
    DeviceLoginController,
    RefreshAccessController,
  ],
  providers: [AuthService, UserGuard, AuthGateway],
  exports: [AuthService, UserGuard],
})
export class AuthModule {}

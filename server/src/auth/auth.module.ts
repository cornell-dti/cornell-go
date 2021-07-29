import { Module } from '@nestjs/common';
import { GoogleController } from './google/google.controller';
import { AppleController } from './apple/apple.controller';
import { DeviceLoginController } from './device-login/device-login.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './jwt.strategy';
import { UserModule } from '../user/user.module';
import { PassportModule } from '@nestjs/passport';
import { JwtModule } from '@nestjs/jwt';
import { RefreshAccessController } from './refresh-access/refresh-access.controller';

@Module({
  imports: [
    UserModule,
    PassportModule,
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
  providers: [AuthService, JwtStrategy],
})
export class AuthModule {}

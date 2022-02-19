import { forwardRef, Module } from '@nestjs/common';
import { GoogleController } from './google/google.controller';
import { AppleController } from './apple/apple.controller';
import { DeviceLoginController } from './device-login/device-login.controller';
import { AuthService } from './auth.service';
import { UserModule } from '../user/user.module';
import { JwtModule } from '@nestjs/jwt';
import { RefreshAccessController } from './refresh-access/refresh-access.controller';
import { User } from 'src/model/user.entity';
import { MikroOrmModule } from '@mikro-orm/nestjs';

@Module({
  imports: [
    forwardRef(() => UserModule),
    JwtModule.register({
      secret: process.env.JWT_ACCESS_SECRET,
      signOptions: { expiresIn: process.env.JWT_ACCESS_EXPIRATION },
    }),
    MikroOrmModule.forFeature([User]),
  ],
  controllers: [
    GoogleController,
    AppleController,
    DeviceLoginController,
    RefreshAccessController,
  ],
  providers: [AuthService],
  exports: [AuthService],
})
export class AuthModule {}

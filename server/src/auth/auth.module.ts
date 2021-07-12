import { Module } from '@nestjs/common';
import { GoogleController } from './google/google.controller';
import { AppleController } from './apple/apple.controller';

@Module({
  controllers: [GoogleController, AppleController]
})
export class AuthModule {}

import { Controller, Get } from '@nestjs/common';

@Controller('feature-flags')
export class FeatureFlagsController {
  @Get()
  getFlags() {
    return {
      enableBuildABear: process.env.ENABLE_BUILD_A_BEAR === 'true',
    };
  }
}

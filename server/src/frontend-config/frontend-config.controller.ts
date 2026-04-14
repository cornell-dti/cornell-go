import { Controller, Get } from '@nestjs/common';

@Controller('frontend-config')
export class FrontendConfigController {
  @Get()
  getConfig() {
    return {
      googleMapsApiKey: process.env.REACT_APP_GOOGLE_MAPS_API_KEY ?? '',
    };
  }
}

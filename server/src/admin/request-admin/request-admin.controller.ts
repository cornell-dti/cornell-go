import { Body, Controller, Post } from '@nestjs/common';
import { AdminService } from '../admin.service';
import { RequestAdminDto } from './request-admin.dto';
@Controller('request-admin')
export class RequestAdminController {
  constructor(private adminService: AdminService) {}

  @Post()
  async requestAdmin(@Body() data: RequestAdminDto) {
    await this.adminService.requestAdminAccess(data.id);
  }
}

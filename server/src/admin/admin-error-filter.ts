import { Catch, ArgumentsHost } from '@nestjs/common';
import { BaseWsExceptionFilter } from '@nestjs/websockets';
import { AdminCallbackService } from './admin-callback/admin-callback.service';
import { WsException } from '@nestjs/websockets/errors/ws-exception';

@Catch()
export class AllExceptionsFilter extends BaseWsExceptionFilter {
  constructor(private adminService: AdminCallbackService) {
    super();
  }
  catch(exception: any, host: ArgumentsHost) {
    super.catch(exception, host);
    console.log('error');
    if (!(exception instanceof WsException)) {
      this.adminService.emitUpdateErrorData({ message: exception.message });
    } else {
      const message = 'error ' + exception.getError();
      this.adminService.emitUpdateErrorData({ message: message });
    }
  }
}

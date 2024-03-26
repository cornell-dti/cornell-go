import {
  INestApplication,
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  async onModuleInit() {
    if (process.env.TESTING_UNIT === 'true') {
      return;
    }

    await this.$connect();
  }

  async onModuleDestroy() {
    if (process.env.TESTING_UNIT === 'true') {
      return;
    }

    await this.$disconnect();
  }

  /* 
  async enableShutdownHooks(app: INestApplication) {
    this.$on('beforeExit', async () => {
      await app.close();
    });
  } 
  */
}

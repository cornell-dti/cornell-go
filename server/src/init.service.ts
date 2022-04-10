import { MikroORM } from '@mikro-orm/core';
import { Injectable, OnModuleInit } from '@nestjs/common';

@Injectable()
export class InitService implements OnModuleInit {
  constructor(private orm: MikroORM) {}
  async onModuleInit() {
    const migrator = this.orm.getMigrator();
    await migrator.up();
    /*if (process.env.DEVELOPMENT) {
      await this.orm.getSchemaGenerator().ensureDatabase();
      await this.orm.getSchemaGenerator().updateSchema();
    }*/
  }
}

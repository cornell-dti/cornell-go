import { Migration } from '@mikro-orm/migrations';

export class Migration20220416162615 extends Migration {
  async up(): Promise<void> {
    this.addSql(
      'alter table "event_base" add column "minimum_score" int not null default 1;',
    );
  }

  async down(): Promise<void> {
    this.addSql('alter table "event_base" drop column "minimum_score";');
  }
}

import { Migration } from '@mikro-orm/migrations';

export class Migration20220426163141 extends Migration {

  async up(): Promise<void> {
    this.addSql('create table "restriction_group" ("id" varchar(255) not null, "display_name" varchar(255) not null, "name" varchar(255) not null, "can_edit_username" boolean not null);');
    this.addSql('alter table "restriction_group" add constraint "restriction_group_pkey" primary key ("id");');

    this.addSql('create table "restriction_group_allowed_events" ("restriction_group_id" varchar(255) not null, "event_base_id" varchar(255) not null);');
    this.addSql('alter table "restriction_group_allowed_events" add constraint "restriction_group_allowed_events_pkey" primary key ("restriction_group_id", "event_base_id");');

    this.addSql('alter table "restriction_group_allowed_events" add constraint "restriction_group_allowed_events_restriction_group_id_foreign" foreign key ("restriction_group_id") references "restriction_group" ("id") on update cascade on delete cascade;');
    this.addSql('alter table "restriction_group_allowed_events" add constraint "restriction_group_allowed_events_event_base_id_foreign" foreign key ("event_base_id") references "event_base" ("id") on update cascade on delete cascade;');

    this.addSql('alter table "event_reward" drop constraint "event_reward_claiming_user_id_foreign";');

    this.addSql('alter table "user" add column "generated_by_id" varchar(255) null, add column "restricted_by_id" varchar(255) null;');
    this.addSql('alter table "user" add constraint "user_generated_by_id_foreign" foreign key ("generated_by_id") references "restriction_group" ("id") on update cascade on delete set null;');
    this.addSql('alter table "user" add constraint "user_restricted_by_id_foreign" foreign key ("restricted_by_id") references "restriction_group" ("id") on update cascade on delete set null;');

    this.addSql('alter table "event_reward" add constraint "event_reward_claiming_user_id_foreign" foreign key ("claiming_user_id") references "user" ("id") on update cascade on delete cascade;');
  }

  async down(): Promise<void> {
    this.addSql('alter table "user" drop constraint "user_generated_by_id_foreign";');

    this.addSql('alter table "user" drop constraint "user_restricted_by_id_foreign";');

    this.addSql('alter table "restriction_group_allowed_events" drop constraint "restriction_group_allowed_events_restriction_group_id_foreign";');

    this.addSql('drop table if exists "restriction_group" cascade;');

    this.addSql('drop table if exists "restriction_group_allowed_events" cascade;');

    this.addSql('alter table "event_reward" drop constraint "event_reward_claiming_user_id_foreign";');

    this.addSql('alter table "user" drop column "generated_by_id";');
    this.addSql('alter table "user" drop column "restricted_by_id";');

    this.addSql('alter table "event_reward" add constraint "event_reward_claiming_user_id_foreign" foreign key ("claiming_user_id") references "user" ("id") on update cascade on delete set null;');
  }

}

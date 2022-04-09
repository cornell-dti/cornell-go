import { Migration } from '@mikro-orm/migrations';

export class Migration20220409231745 extends Migration {
  async up(): Promise<void> {
    this.addSql(
      'create table "event_base" ("id" varchar(255) not null, "required_members" int not null, "skipping_enabled" boolean not null, "is_default" boolean not null, "name" varchar(255) not null, "description" varchar(255) not null, "reward_type" text check ("reward_type" in (\'limited_time_event\', \'perpetual\')) not null, "indexable" boolean not null, "time" timestamptz(0) not null);',
    );
    this.addSql(
      'create index "event_base_is_default_index" on "event_base" ("is_default");',
    );
    this.addSql(
      'alter table "event_base" add constraint "event_base_pkey" primary key ("id");',
    );

    this.addSql(
      'create table "group" ("id" varchar(255) not null, "current_event_id" varchar(255) not null, "friendly_id" varchar(255) not null, "host_id" varchar(255) null);',
    );
    this.addSql(
      'alter table "group" add constraint "group_friendly_id_unique" unique ("friendly_id");',
    );
    this.addSql(
      'alter table "group" add constraint "group_host_id_unique" unique ("host_id");',
    );
    this.addSql(
      'alter table "group" add constraint "group_pkey" primary key ("id");',
    );

    this.addSql(
      'create table "user" ("id" varchar(255) not null, "auth_token" varchar(2048) not null, "auth_type" text check ("auth_type" in (\'google\', \'apple\', \'device\', \'none\')) not null, "username" varchar(2048) not null, "email" varchar(2048) not null, "hashed_refresh_token" varchar(2048) not null, "superuser" boolean not null, "admin_granted" boolean not null, "admin_requested" boolean not null, "score" int not null, "group_id" varchar(255) null);',
    );
    this.addSql(
      'alter table "user" add constraint "user_auth_token_unique" unique ("auth_token");',
    );
    this.addSql('create index "user_auth_type_index" on "user" ("auth_type");');
    this.addSql('create index "user_score_index" on "user" ("score");');
    this.addSql(
      'alter table "user" add constraint "user_pkey" primary key ("id");',
    );

    this.addSql(
      'create table "event_reward" ("id" varchar(255) not null, "containing_event_id" varchar(255) not null, "claiming_user_id" varchar(255) null, "reward_description" varchar(255) not null, "reward_redeem_info" varchar(255) not null, "is_redeemed" boolean not null);',
    );
    this.addSql(
      'alter table "event_reward" add constraint "event_reward_pkey" primary key ("id");',
    );

    this.addSql(
      "create table \"session_log_entry\" (\"id\" serial primary key, \"entry_type\" text check (\"entry_type\" in ('user_created', 'login', 'logout', 'found_place', 'join_group', 'some_user_joined_group', 'some_user_left_group', 'left_group', 'change_username', 'kicked_member', 'disbanded_group', 'kicked_by_host', 'user_joined_event', 'user_chose_event', 'user_earned_reward')) not null, \"associated_uuid\" varchar(255) null, \"user_id\" varchar(255) not null);",
    );

    this.addSql(
      'create table "challenge" ("id" varchar(255) not null, "event_index" int not null, "name" varchar(2048) not null, "description" varchar(2048) not null, "image_url" varchar(2048) not null, "latitude" double precision not null, "longitude" double precision not null, "linked_event_id" varchar(255) not null, "awarding_radius" double precision not null, "close_radius" double precision not null);',
    );
    this.addSql(
      'create index "challenge_event_index_index" on "challenge" ("event_index");',
    );
    this.addSql(
      'alter table "challenge" add constraint "challenge_pkey" primary key ("id");',
    );

    this.addSql(
      'create table "event_tracker" ("id" varchar(255) not null, "event_score" int not null, "is_player_ranked" boolean not null, "cooldown_minimum" timestamptz(0) not null, "user_id" varchar(255) not null, "event_id" varchar(255) not null, "current_challenge_id" varchar(255) not null);',
    );
    this.addSql(
      'create index "event_tracker_event_score_index" on "event_tracker" ("event_score");',
    );
    this.addSql(
      'alter table "event_tracker" add constraint "event_tracker_pkey" primary key ("id");',
    );

    this.addSql(
      'create table "prev_challenge" ("id" serial primary key, "found_timestamp" timestamptz(0) not null, "owner_id" varchar(255) not null, "challenge_id" varchar(255) not null);',
    );

    this.addSql(
      'create table "event_tracker_completed" ("event_tracker_id" varchar(255) not null, "prev_challenge_id" int not null);',
    );
    this.addSql(
      'alter table "event_tracker_completed" add constraint "event_tracker_completed_pkey" primary key ("event_tracker_id", "prev_challenge_id");',
    );

    this.addSql(
      'create table "prev_challenge_completion_players" ("prev_challenge_id" int not null, "user_id" varchar(255) not null);',
    );
    this.addSql(
      'alter table "prev_challenge_completion_players" add constraint "prev_challenge_completion_players_pkey" primary key ("prev_challenge_id", "user_id");',
    );

    this.addSql(
      'alter table "group" add constraint "group_current_event_id_foreign" foreign key ("current_event_id") references "event_base" ("id") on update cascade;',
    );
    this.addSql(
      'alter table "group" add constraint "group_host_id_foreign" foreign key ("host_id") references "user" ("id") on update cascade on delete set null;',
    );

    this.addSql(
      'alter table "user" add constraint "user_group_id_foreign" foreign key ("group_id") references "group" ("id") on update cascade on delete set null;',
    );

    this.addSql(
      'alter table "event_reward" add constraint "event_reward_containing_event_id_foreign" foreign key ("containing_event_id") references "event_base" ("id") on update cascade;',
    );
    this.addSql(
      'alter table "event_reward" add constraint "event_reward_claiming_user_id_foreign" foreign key ("claiming_user_id") references "user" ("id") on update cascade on delete set null;',
    );

    this.addSql(
      'alter table "session_log_entry" add constraint "session_log_entry_user_id_foreign" foreign key ("user_id") references "user" ("id") on update cascade;',
    );

    this.addSql(
      'alter table "challenge" add constraint "challenge_linked_event_id_foreign" foreign key ("linked_event_id") references "event_base" ("id") on update cascade;',
    );

    this.addSql(
      'alter table "event_tracker" add constraint "event_tracker_user_id_foreign" foreign key ("user_id") references "user" ("id") on update cascade;',
    );
    this.addSql(
      'alter table "event_tracker" add constraint "event_tracker_event_id_foreign" foreign key ("event_id") references "event_base" ("id") on update cascade;',
    );
    this.addSql(
      'alter table "event_tracker" add constraint "event_tracker_current_challenge_id_foreign" foreign key ("current_challenge_id") references "challenge" ("id") on update cascade;',
    );

    this.addSql(
      'alter table "prev_challenge" add constraint "prev_challenge_owner_id_foreign" foreign key ("owner_id") references "user" ("id") on update cascade;',
    );
    this.addSql(
      'alter table "prev_challenge" add constraint "prev_challenge_challenge_id_foreign" foreign key ("challenge_id") references "challenge" ("id") on update cascade;',
    );

    this.addSql(
      'alter table "event_tracker_completed" add constraint "event_tracker_completed_event_tracker_id_foreign" foreign key ("event_tracker_id") references "event_tracker" ("id") on update cascade on delete cascade;',
    );
    this.addSql(
      'alter table "event_tracker_completed" add constraint "event_tracker_completed_prev_challenge_id_foreign" foreign key ("prev_challenge_id") references "prev_challenge" ("id") on update cascade on delete cascade;',
    );

    this.addSql(
      'alter table "prev_challenge_completion_players" add constraint "prev_challenge_completion_players_prev_challenge_id_foreign" foreign key ("prev_challenge_id") references "prev_challenge" ("id") on update cascade on delete cascade;',
    );
    this.addSql(
      'alter table "prev_challenge_completion_players" add constraint "prev_challenge_completion_players_user_id_foreign" foreign key ("user_id") references "user" ("id") on update cascade on delete cascade;',
    );
  }

  async down(): Promise<void> {
    this.addSql(
      'alter table "group" drop constraint "group_current_event_id_foreign";',
    );

    this.addSql(
      'alter table "event_reward" drop constraint "event_reward_containing_event_id_foreign";',
    );

    this.addSql(
      'alter table "challenge" drop constraint "challenge_linked_event_id_foreign";',
    );

    this.addSql(
      'alter table "event_tracker" drop constraint "event_tracker_event_id_foreign";',
    );

    this.addSql('alter table "user" drop constraint "user_group_id_foreign";');

    this.addSql('alter table "group" drop constraint "group_host_id_foreign";');

    this.addSql(
      'alter table "event_reward" drop constraint "event_reward_claiming_user_id_foreign";',
    );

    this.addSql(
      'alter table "session_log_entry" drop constraint "session_log_entry_user_id_foreign";',
    );

    this.addSql(
      'alter table "event_tracker" drop constraint "event_tracker_user_id_foreign";',
    );

    this.addSql(
      'alter table "prev_challenge" drop constraint "prev_challenge_owner_id_foreign";',
    );

    this.addSql(
      'alter table "prev_challenge_completion_players" drop constraint "prev_challenge_completion_players_user_id_foreign";',
    );

    this.addSql(
      'alter table "event_tracker" drop constraint "event_tracker_current_challenge_id_foreign";',
    );

    this.addSql(
      'alter table "prev_challenge" drop constraint "prev_challenge_challenge_id_foreign";',
    );

    this.addSql(
      'alter table "event_tracker_completed" drop constraint "event_tracker_completed_event_tracker_id_foreign";',
    );

    this.addSql(
      'alter table "event_tracker_completed" drop constraint "event_tracker_completed_prev_challenge_id_foreign";',
    );

    this.addSql(
      'alter table "prev_challenge_completion_players" drop constraint "prev_challenge_completion_players_prev_challenge_id_foreign";',
    );

    this.addSql('drop table if exists "event_base" cascade;');

    this.addSql('drop table if exists "group" cascade;');

    this.addSql('drop table if exists "user" cascade;');

    this.addSql('drop table if exists "event_reward" cascade;');

    this.addSql('drop table if exists "session_log_entry" cascade;');

    this.addSql('drop table if exists "challenge" cascade;');

    this.addSql('drop table if exists "event_tracker" cascade;');

    this.addSql('drop table if exists "prev_challenge" cascade;');

    this.addSql('drop table if exists "event_tracker_completed" cascade;');

    this.addSql(
      'drop table if exists "prev_challenge_completion_players" cascade;',
    );
  }
}

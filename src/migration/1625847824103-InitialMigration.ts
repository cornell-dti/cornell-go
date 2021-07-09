import {MigrationInterface, QueryRunner} from "typeorm";

export class InitialMigration1625847824103 implements MigrationInterface {
    name = 'InitialMigration1625847824103'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE "test"."challenge" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "name" character varying NOT NULL, "description" character varying NOT NULL, "imageUrl" character varying NOT NULL, "location" geography(Point,4326) NOT NULL, "awardingRadius" integer NOT NULL, "closeRadius" integer NOT NULL, CONSTRAINT "PK_749e6611d5a5f9b4d03028cbc41" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "IDX_d1b43302906421d747d4732aed" ON "test"."challenge" USING GiST ("location") `);
        await queryRunner.query(`CREATE TABLE "test"."prev_challenge" ("id" SERIAL NOT NULL, "foundTimestamp" TIMESTAMP NOT NULL DEFAULT now(), "challengeId" uuid, CONSTRAINT "PK_5a635ff737af75b6c8a4374aabb" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "test"."event_progress" ("id" SERIAL NOT NULL, "isPlayerRanked" boolean NOT NULL, "cooldownMinimum" TIMESTAMP WITH TIME ZONE NOT NULL, "playerId" uuid, "eventId" uuid, CONSTRAINT "PK_ae2382b15a5ae4c134513de24d6" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "test"."group" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "currentEventId" uuid, CONSTRAINT "PK_ab8dbce569e4e229745ca845c8a" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "test"."group_member" ("id" SERIAL NOT NULL, "isHost" boolean NOT NULL, "groupId" uuid, CONSTRAINT "PK_dd5c1fc5f32a72b9ba2ac60d6d7" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "test"."session_log_entry_entrytype_enum" AS ENUM('user_created', 'login', 'logout', 'found_place', 'join_group', 'some_user_joined_group', 'some_user_left_group', 'left_group', 'change_username', 'kicked_member', 'disbanded_group', 'kicked_by_host', 'user_joined_event', 'user_chose_event', 'user_earned_reward')`);
        await queryRunner.query(`CREATE TABLE "test"."session_log_entry" ("id" SERIAL NOT NULL, "entryType" "test"."session_log_entry_entrytype_enum" NOT NULL, "entryTimestamp" TIMESTAMP NOT NULL DEFAULT now(), "associatedUUID" character varying NOT NULL, "userId" uuid, CONSTRAINT "PK_2548bd89d9f5ed57e6d2e3707e6" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "test"."user_oauthtype_enum" AS ENUM('google', 'apple')`);
        await queryRunner.query(`CREATE TABLE "test"."user" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "oauthToken" character varying NOT NULL, "oauthType" "test"."user_oauthtype_enum" NOT NULL, "username" character varying NOT NULL, "email" character varying NOT NULL, "score" integer NOT NULL, "groupMemberId" integer, CONSTRAINT "REL_502d12589e4d808e3a1d18dbab" UNIQUE ("groupMemberId"), CONSTRAINT "PK_d96d7dbdf10d76556f90a6b2d0f" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "test"."event_reward" ("id" SERIAL NOT NULL, "rewardDescription" character varying NOT NULL, "rewardRedeemInfo" character varying NOT NULL, "isInfoLink" boolean NOT NULL, "containingEventId" uuid, "claimingUserId" uuid, CONSTRAINT "PK_4812bd8edb6b2cb17b0cd04b759" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "test"."event_base_rewardtype_enum" AS ENUM('limited_time_event', 'win_on_completion', 'race_to_win', 'no_rewards')`);
        await queryRunner.query(`CREATE TABLE "test"."event_base" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "minMembers" integer NOT NULL, "skippingEnabled" boolean NOT NULL, "hasStarChallenge" boolean NOT NULL, "name" character varying NOT NULL, "description" character varying NOT NULL, "rewardType" "test"."event_base_rewardtype_enum" NOT NULL DEFAULT 'no_rewards', "time" TIMESTAMP NOT NULL, "topCount" integer NOT NULL, CONSTRAINT "PK_db6a4bc752ed70d6b8c5e43811c" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "test"."prev_challenge_completion_players_user" ("prevChallengeId" integer NOT NULL, "userId" uuid NOT NULL, CONSTRAINT "PK_5eed8751c794eadb2f6586227d7" PRIMARY KEY ("prevChallengeId", "userId"))`);
        await queryRunner.query(`CREATE INDEX "IDX_8a9f12427ffbd434886e07bc8f" ON "test"."prev_challenge_completion_players_user" ("prevChallengeId") `);
        await queryRunner.query(`CREATE INDEX "IDX_c737f4534b98d401a6c8948f6b" ON "test"."prev_challenge_completion_players_user" ("userId") `);
        await queryRunner.query(`ALTER TABLE "test"."prev_challenge" ADD CONSTRAINT "FK_3ae837b1a3d1403b3e28b0c0b97" FOREIGN KEY ("challengeId") REFERENCES "test"."challenge"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "test"."event_progress" ADD CONSTRAINT "FK_a6e9c7e800c694505a9321ac89b" FOREIGN KEY ("playerId") REFERENCES "test"."user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "test"."event_progress" ADD CONSTRAINT "FK_2901aa0b096ad19d64bfe0dd4e4" FOREIGN KEY ("eventId") REFERENCES "test"."event_base"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "test"."group" ADD CONSTRAINT "FK_f901ac14ec4dc190aff6515efb2" FOREIGN KEY ("currentEventId") REFERENCES "test"."event_base"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "test"."group_member" ADD CONSTRAINT "FK_91eff8b9863d5008e57077bfc70" FOREIGN KEY ("groupId") REFERENCES "test"."group"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "test"."session_log_entry" ADD CONSTRAINT "FK_0abf19f27da58b94d144d8af366" FOREIGN KEY ("userId") REFERENCES "test"."user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "test"."user" ADD CONSTRAINT "FK_502d12589e4d808e3a1d18dbab9" FOREIGN KEY ("groupMemberId") REFERENCES "test"."group_member"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "test"."event_reward" ADD CONSTRAINT "FK_7b7ce84738e29ee0a04f3308793" FOREIGN KEY ("containingEventId") REFERENCES "test"."event_base"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "test"."event_reward" ADD CONSTRAINT "FK_aaed4e664a609060166eae4e060" FOREIGN KEY ("claimingUserId") REFERENCES "test"."user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "test"."prev_challenge_completion_players_user" ADD CONSTRAINT "FK_8a9f12427ffbd434886e07bc8fc" FOREIGN KEY ("prevChallengeId") REFERENCES "test"."prev_challenge"("id") ON DELETE CASCADE ON UPDATE CASCADE`);
        await queryRunner.query(`ALTER TABLE "test"."prev_challenge_completion_players_user" ADD CONSTRAINT "FK_c737f4534b98d401a6c8948f6b5" FOREIGN KEY ("userId") REFERENCES "test"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "test"."prev_challenge_completion_players_user" DROP CONSTRAINT "FK_c737f4534b98d401a6c8948f6b5"`);
        await queryRunner.query(`ALTER TABLE "test"."prev_challenge_completion_players_user" DROP CONSTRAINT "FK_8a9f12427ffbd434886e07bc8fc"`);
        await queryRunner.query(`ALTER TABLE "test"."event_reward" DROP CONSTRAINT "FK_aaed4e664a609060166eae4e060"`);
        await queryRunner.query(`ALTER TABLE "test"."event_reward" DROP CONSTRAINT "FK_7b7ce84738e29ee0a04f3308793"`);
        await queryRunner.query(`ALTER TABLE "test"."user" DROP CONSTRAINT "FK_502d12589e4d808e3a1d18dbab9"`);
        await queryRunner.query(`ALTER TABLE "test"."session_log_entry" DROP CONSTRAINT "FK_0abf19f27da58b94d144d8af366"`);
        await queryRunner.query(`ALTER TABLE "test"."group_member" DROP CONSTRAINT "FK_91eff8b9863d5008e57077bfc70"`);
        await queryRunner.query(`ALTER TABLE "test"."group" DROP CONSTRAINT "FK_f901ac14ec4dc190aff6515efb2"`);
        await queryRunner.query(`ALTER TABLE "test"."event_progress" DROP CONSTRAINT "FK_2901aa0b096ad19d64bfe0dd4e4"`);
        await queryRunner.query(`ALTER TABLE "test"."event_progress" DROP CONSTRAINT "FK_a6e9c7e800c694505a9321ac89b"`);
        await queryRunner.query(`ALTER TABLE "test"."prev_challenge" DROP CONSTRAINT "FK_3ae837b1a3d1403b3e28b0c0b97"`);
        await queryRunner.query(`DROP INDEX "test"."IDX_c737f4534b98d401a6c8948f6b"`);
        await queryRunner.query(`DROP INDEX "test"."IDX_8a9f12427ffbd434886e07bc8f"`);
        await queryRunner.query(`DROP TABLE "test"."prev_challenge_completion_players_user"`);
        await queryRunner.query(`DROP TABLE "test"."event_base"`);
        await queryRunner.query(`DROP TYPE "test"."event_base_rewardtype_enum"`);
        await queryRunner.query(`DROP TABLE "test"."event_reward"`);
        await queryRunner.query(`DROP TABLE "test"."user"`);
        await queryRunner.query(`DROP TYPE "test"."user_oauthtype_enum"`);
        await queryRunner.query(`DROP TABLE "test"."session_log_entry"`);
        await queryRunner.query(`DROP TYPE "test"."session_log_entry_entrytype_enum"`);
        await queryRunner.query(`DROP TABLE "test"."group_member"`);
        await queryRunner.query(`DROP TABLE "test"."group"`);
        await queryRunner.query(`DROP TABLE "test"."event_progress"`);
        await queryRunner.query(`DROP TABLE "test"."prev_challenge"`);
        await queryRunner.query(`DROP INDEX "test"."IDX_d1b43302906421d747d4732aed"`);
        await queryRunner.query(`DROP TABLE "test"."challenge"`);
    }

}

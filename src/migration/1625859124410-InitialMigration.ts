import {MigrationInterface, QueryRunner} from "typeorm";

export class InitialMigration1625859124410 implements MigrationInterface {
    name = 'InitialMigration1625859124410'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE "public"."challenge" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "name" character varying NOT NULL, "description" character varying NOT NULL, "imageUrl" character varying NOT NULL, "location" geography(Point,4326) NOT NULL, "awardingRadius" integer NOT NULL, "closeRadius" integer NOT NULL, CONSTRAINT "PK_82ab56a73911660bfbce2320ea1" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "IDX_3473ed7914b06b3bbe9becf4a3" ON "public"."challenge" USING GiST ("location") `);
        await queryRunner.query(`CREATE TABLE "public"."prev_challenge" ("id" SERIAL NOT NULL, "foundTimestamp" TIMESTAMP NOT NULL DEFAULT now(), "challengeId" uuid, CONSTRAINT "PK_b01af1d80e034729ada3979392f" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "public"."event_progress" ("id" SERIAL NOT NULL, "isPlayerRanked" boolean NOT NULL, "cooldownMinimum" TIMESTAMP WITH TIME ZONE NOT NULL, "playerId" uuid, "eventId" uuid, CONSTRAINT "PK_291c7e943045b0d70b209342bfe" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "public"."group" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "currentEventId" uuid, CONSTRAINT "PK_fe845bf655bc27966bd9225d968" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "public"."group_member" ("id" SERIAL NOT NULL, "isHost" boolean NOT NULL, "groupId" uuid, CONSTRAINT "PK_50d3e9c658062d37df80f0631b8" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."session_log_entry_entrytype_enum" AS ENUM('user_created', 'login', 'logout', 'found_place', 'join_group', 'some_user_joined_group', 'some_user_left_group', 'left_group', 'change_username', 'kicked_member', 'disbanded_group', 'kicked_by_host', 'user_joined_event', 'user_chose_event', 'user_earned_reward')`);
        await queryRunner.query(`CREATE TABLE "public"."session_log_entry" ("id" SERIAL NOT NULL, "entryType" "public"."session_log_entry_entrytype_enum" NOT NULL, "entryTimestamp" TIMESTAMP NOT NULL DEFAULT now(), "associatedUUID" character varying NOT NULL, "userId" uuid, CONSTRAINT "PK_3a432f9c74680c0a1a94c0e3cb6" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."user_oauthtype_enum" AS ENUM('google', 'apple')`);
        await queryRunner.query(`CREATE TABLE "public"."user" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "oauthToken" character varying NOT NULL, "oauthType" "public"."user_oauthtype_enum" NOT NULL, "username" character varying NOT NULL, "email" character varying NOT NULL, "score" integer NOT NULL, "groupMemberId" integer, CONSTRAINT "REL_6c55e5dc11fd175603512c92e1" UNIQUE ("groupMemberId"), CONSTRAINT "PK_03b91d2b8321aa7ba32257dc321" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "public"."event_reward" ("id" SERIAL NOT NULL, "rewardDescription" character varying NOT NULL, "rewardRedeemInfo" character varying NOT NULL, "isInfoLink" boolean NOT NULL, "containingEventId" uuid, "claimingUserId" uuid, CONSTRAINT "PK_044b866287e5867c5c367b37723" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."event_base_rewardtype_enum" AS ENUM('limited_time_event', 'win_on_completion', 'race_to_win', 'no_rewards')`);
        await queryRunner.query(`CREATE TABLE "public"."event_base" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "minMembers" integer NOT NULL, "skippingEnabled" boolean NOT NULL, "hasStarChallenge" boolean NOT NULL, "name" character varying NOT NULL, "description" character varying NOT NULL, "rewardType" "public"."event_base_rewardtype_enum" NOT NULL DEFAULT 'no_rewards', "time" TIMESTAMP NOT NULL, "topCount" integer NOT NULL, CONSTRAINT "PK_eab485e62c53a8cd71605e55bdf" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "public"."prev_challenge_completion_players_user" ("prevChallengeId" integer NOT NULL, "userId" uuid NOT NULL, CONSTRAINT "PK_7662b4a9449bae6354e4e12974a" PRIMARY KEY ("prevChallengeId", "userId"))`);
        await queryRunner.query(`CREATE INDEX "IDX_823f62d583f7be263be1e1f2ac" ON "public"."prev_challenge_completion_players_user" ("prevChallengeId") `);
        await queryRunner.query(`CREATE INDEX "IDX_46a7370a6797b24a1c890741f2" ON "public"."prev_challenge_completion_players_user" ("userId") `);
        await queryRunner.query(`ALTER TABLE "public"."prev_challenge" ADD CONSTRAINT "FK_eeb1b66cb824e4c64a4a2c816b0" FOREIGN KEY ("challengeId") REFERENCES "public"."challenge"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "public"."event_progress" ADD CONSTRAINT "FK_5a339c35149b508e639517e585b" FOREIGN KEY ("playerId") REFERENCES "public"."user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "public"."event_progress" ADD CONSTRAINT "FK_10dc052a4369f6bb38cd7cae9b1" FOREIGN KEY ("eventId") REFERENCES "public"."event_base"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "public"."group" ADD CONSTRAINT "FK_2a59da7aef0db15aa3db1b9c549" FOREIGN KEY ("currentEventId") REFERENCES "public"."event_base"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "public"."group_member" ADD CONSTRAINT "FK_d5222de2f0d0e55890e6ba3093e" FOREIGN KEY ("groupId") REFERENCES "public"."group"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "public"."session_log_entry" ADD CONSTRAINT "FK_80b294447b81847b1fe6051005a" FOREIGN KEY ("userId") REFERENCES "public"."user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "public"."user" ADD CONSTRAINT "FK_6c55e5dc11fd175603512c92e1f" FOREIGN KEY ("groupMemberId") REFERENCES "public"."group_member"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "public"."event_reward" ADD CONSTRAINT "FK_fc9b203027cba967d66ea6ead22" FOREIGN KEY ("containingEventId") REFERENCES "public"."event_base"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "public"."event_reward" ADD CONSTRAINT "FK_0f921fc0afa10ab195db21c9591" FOREIGN KEY ("claimingUserId") REFERENCES "public"."user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "public"."prev_challenge_completion_players_user" ADD CONSTRAINT "FK_823f62d583f7be263be1e1f2ac7" FOREIGN KEY ("prevChallengeId") REFERENCES "public"."prev_challenge"("id") ON DELETE CASCADE ON UPDATE CASCADE`);
        await queryRunner.query(`ALTER TABLE "public"."prev_challenge_completion_players_user" ADD CONSTRAINT "FK_46a7370a6797b24a1c890741f2b" FOREIGN KEY ("userId") REFERENCES "public"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "public"."prev_challenge_completion_players_user" DROP CONSTRAINT "FK_46a7370a6797b24a1c890741f2b"`);
        await queryRunner.query(`ALTER TABLE "public"."prev_challenge_completion_players_user" DROP CONSTRAINT "FK_823f62d583f7be263be1e1f2ac7"`);
        await queryRunner.query(`ALTER TABLE "public"."event_reward" DROP CONSTRAINT "FK_0f921fc0afa10ab195db21c9591"`);
        await queryRunner.query(`ALTER TABLE "public"."event_reward" DROP CONSTRAINT "FK_fc9b203027cba967d66ea6ead22"`);
        await queryRunner.query(`ALTER TABLE "public"."user" DROP CONSTRAINT "FK_6c55e5dc11fd175603512c92e1f"`);
        await queryRunner.query(`ALTER TABLE "public"."session_log_entry" DROP CONSTRAINT "FK_80b294447b81847b1fe6051005a"`);
        await queryRunner.query(`ALTER TABLE "public"."group_member" DROP CONSTRAINT "FK_d5222de2f0d0e55890e6ba3093e"`);
        await queryRunner.query(`ALTER TABLE "public"."group" DROP CONSTRAINT "FK_2a59da7aef0db15aa3db1b9c549"`);
        await queryRunner.query(`ALTER TABLE "public"."event_progress" DROP CONSTRAINT "FK_10dc052a4369f6bb38cd7cae9b1"`);
        await queryRunner.query(`ALTER TABLE "public"."event_progress" DROP CONSTRAINT "FK_5a339c35149b508e639517e585b"`);
        await queryRunner.query(`ALTER TABLE "public"."prev_challenge" DROP CONSTRAINT "FK_eeb1b66cb824e4c64a4a2c816b0"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_46a7370a6797b24a1c890741f2"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_823f62d583f7be263be1e1f2ac"`);
        await queryRunner.query(`DROP TABLE "public"."prev_challenge_completion_players_user"`);
        await queryRunner.query(`DROP TABLE "public"."event_base"`);
        await queryRunner.query(`DROP TYPE "public"."event_base_rewardtype_enum"`);
        await queryRunner.query(`DROP TABLE "public"."event_reward"`);
        await queryRunner.query(`DROP TABLE "public"."user"`);
        await queryRunner.query(`DROP TYPE "public"."user_oauthtype_enum"`);
        await queryRunner.query(`DROP TABLE "public"."session_log_entry"`);
        await queryRunner.query(`DROP TYPE "public"."session_log_entry_entrytype_enum"`);
        await queryRunner.query(`DROP TABLE "public"."group_member"`);
        await queryRunner.query(`DROP TABLE "public"."group"`);
        await queryRunner.query(`DROP TABLE "public"."event_progress"`);
        await queryRunner.query(`DROP TABLE "public"."prev_challenge"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_3473ed7914b06b3bbe9becf4a3"`);
        await queryRunner.query(`DROP TABLE "public"."challenge"`);
    }

}

const { execSync } = require("child_process");
const { rmSync, mkdirSync, existsSync } = require("fs");
const { chdir } = require("process");

async function main() {
  console.log("Stopping containers");
  execSync("docker compose stop");
  if (!existsSync("./postgres-data")) {
    console.log("postgres-data not found, creating one");
    mkdirSync("./postgres-data");
  } else if (existsSync("./postgres-data/pgdata")) {
    console.log("Clearing local database data");
    rmSync("./postgres-data/pgdata", { recursive: true, force: true });
  }

  console.log("Starting postgres server to set up database");
  execSync("docker compose up -d --wait postgres");
  chdir("./server");

  console.log("Syncing prisma schema");
  execSync("npx prisma db push --accept-data-loss --force-reset");

  console.log("Stopping containers");
  execSync("docker compose stop");

  console.log("Successfully reset the database!");
}

main();

const { execSync } = require("child_process");
const { rmSync, mkdirSync, readFileSync, writeFileSync } = require("fs");
const { chdir } = require("process");

async function main() {
  execSync("docker compose stop");
  try {
    mkdirSync("./postgres-data");
    rmSync("./postgres-data/pgdata", { recursive: true, force: true });
  } catch { }
  execSync("docker compose up -d");
  chdir("./server");

  execSync("npx prisma db push --accept-data-loss --force-reset");

  execSync("docker compose stop");
}

main();

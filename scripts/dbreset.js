const { execSync } = require("child_process");
const { rmSync, mkdirSync, readFileSync, writeFileSync } = require("fs");
const { chdir } = require("process");

async function main() {
  execSync("docker compose stop");
  try {
    mkdirSync("./postgres-data");
    rmSync("./postgres-data/pgdata", { recursive: true, force: true });
  } catch {
  }
  execSync("docker compose up -d");
  chdir("./server");

  const oldEnv = readFileSync("./.env", "utf-8");
  //writeFileSync("./.env", "DATABASE_URL=postgresql://postgres:test@localhost:5432/postgres", { encoding: 'utf-8', flag: 'w' });
  execSync("npx prisma db push --force-reset");
  //writeFileSync("./.env", oldEnv, { encoding: 'utf-8', flag: 'w' });

  execSync("docker compose stop");
}

main()
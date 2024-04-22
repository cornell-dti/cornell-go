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

  process.env[`DB_RESET`] = "true";
  console.log("Setting up database through docker");
  execSync(
    "docker compose up --build --no-attach postgres --exit-code-from server",
  );

  console.log("Successfully reset the database!");
}

main();

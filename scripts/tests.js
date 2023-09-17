const { execSync } = require("child_process");
const { cpSync, rmSync, existsSync } = require("fs");

async function main() {
  if (process.argv.length < 3 || !(["unit", "e2e"].includes(process.argv[2]))) {
    console.log("USAGE: npm run tests -- <unit | e2e>");
    return;
  }

  const testType = process.argv[2].toUpperCase();
  const saveOldPostgres = existsSync("./postgres-data");

  if (saveOldPostgres) {
    cpSync("./postgres-data", "./postgres-data-saved");
  }

  try {
    execSync("npm run dbreset");
    execSync(`TESTING_${testType}=true docker compose up --no-attach postgres`);
  } finally {
    execSync("docker compose stop");
    if (saveOldPostgres) {
      rmSync("./postgres-data");
      cpSync("./postgres-data-saved", "./postgres-data");
    }
  }
}

main();

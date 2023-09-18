const { execSync } = require("child_process");
const { rmSync, existsSync, mkdirSync, readdirSync, lstatSync, copyFileSync } = require("fs");
const path = require("path");

function copyFolderSync(from, to) { // https://stackoverflow.com/questions/13786160/copy-folder-recursively-in-node-js
  mkdirSync(to);
  readdirSync(from).forEach(element => {
    if (lstatSync(path.join(from, element)).isFile()) {
      copyFileSync(path.join(from, element), path.join(to, element));
    } else {
      copyFolderSync(path.join(from, element), path.join(to, element));
    }
  });
}

async function main() {
  if (process.argv.length < 3 || !(["unit", "e2e"].includes(process.argv[2]))) {
    console.log("USAGE: npm run tests -- <unit | e2e>");
    return;
  }

  const testType = process.argv[2].toUpperCase();
  process.env[`TESTING_${testType}`] = "true";

  console.log("Stopping postgres (if running)");
  execSync(`docker compose stop postgres`);

  if (testType === "UNIT") {
    try {
      console.log("Executing unit tests");
      execSync(`docker compose up --no-deps --build server --exit-code-from server`);
      console.log("Tests ran successfully!");
    } catch (err) {
      console.log("Test execution failed!");
      process.exitCode = 1;
    }
  } else if (testType === "E2E") {
    const saveOldPostgres = existsSync("./postgres-data");

    if (existsSync("./postgres-data-saved")) {
      rmSync("./postgres-data-saved", { recursive: true, force: true });
    }

    if (saveOldPostgres) {
      console.log("Backing up database data");
      copyFolderSync("./postgres-data", "./postgres-data-saved");
    }

    try {
      console.log("Setting up test database");
      execSync("npm run dbreset");
      console.log("Executing e2e tests");
      execSync(`docker compose up --build --no-attach postgres --exit-code-from server`);
      console.log("Tests ran successfully!");
    } catch (err) {
      console.log("Test execution failed!");
      process.exitCode = 1;
    } finally {
      console.log("Stopping postgres (if running)");
      execSync(`docker compose stop postgres`);
      console.log("Deleting test database");
      rmSync("./postgres-data", { recursive: true, force: true });
      if (saveOldPostgres) {
        console.log("Restoring database data");
        copyFolderSync("./postgres-data-saved", "./postgres-data");
        rmSync("./postgres-data-saved", { recursive: true, force: true });
      }
    }
  }

  console.log("Finished tests");
}

main();

const { execSync } = require("child_process");
const { rmSync, mkdirSync, existsSync } = require("fs");
const { chdir } = require("process");

/* 
cd ./server
npm install
cd ../admin
npm install
cd ../game
flutter pub get
cd ..
npm run dbreset
*/

async function main() {
  console.log("Checking if docker is installed (will fail if not)");
  execSync("docker compose --version");
  console.log("Checking if flutter is installed (will fail if not)");
  execSync("flutter --version");
  console.log("Installing admin page dependencies");
  chdir("./server");
  execSync("npm install");
  console.log("Installing server dependencies");
  chdir("../admin");
  execSync("npm install");
  console.log("Installing flutter dependencies");
  chdir("../game");
  execSync("flutter pub get");
  console.log("Setting up local database");
  chdir("..");
  execSync("npm run dbreset");
  console.log("Verifying docker compose setup (this may take a while)");
  execSync("npm run tests:e2e");
  console.log("Setup successful!");
}

main();

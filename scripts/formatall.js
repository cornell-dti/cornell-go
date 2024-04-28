const { execSync } = require("child_process");
const { chdir } = require("process");

async function main() {
  console.log("Formatting server...");
  chdir("./server");
  execSync("npm run format");
  console.log("Formatting admin...");
  chdir("../admin");
  execSync("npm run format");
  console.log("Formatting game...");
  chdir("../game");
  execSync("dart format lib");
}

main();

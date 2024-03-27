import { writeFileSync } from "fs";
import { execSync } from "child_process";
import { chdir } from "process";

import {
  genDartDtoFile,
  getDartClientApiFile,
  getDartServerApiFile,
} from "./updateapi-lib/dartgen";
import { getDtoDefinitions } from "./updateapi-lib/dtoscanner";
import { genTsDtoFile, getAdminApiFile } from "./updateapi-lib/tsgen";
import { getApiDefinitions } from "./updateapi-lib/apiscanner";

const flutterDtoPath = "./game/lib/api/game_client_dto.dart";
const adminDtoPath = "./admin/src/all.dto.ts";
const flutterClientApiPath = "./game/lib/api/game_client_api.dart";
const flutterServerApiPath = "./game/lib/api/game_server_api.dart";
const adminApiPath = "./admin/src/components/ServerApi.tsx";

const dtos = getDtoDefinitions();
const apis = getApiDefinitions();

const dartDtoCode = genDartDtoFile(dtos);
const tsDtoCode = genTsDtoFile(dtos);
const tsApiCode = getAdminApiFile(apis);
const dartClientApiCode = getDartClientApiFile(apis);
const dartServerApiCode = getDartServerApiFile(apis);

writeFileSync(flutterDtoPath, dartDtoCode, { encoding: "utf8", flag: "w" });
writeFileSync(adminDtoPath, tsDtoCode, { encoding: "utf8", flag: "w" });
writeFileSync(adminApiPath, tsApiCode, { encoding: "utf8", flag: "w" });
writeFileSync(flutterClientApiPath, dartClientApiCode, {
  encoding: "utf8",
  flag: "w",
});
writeFileSync(flutterServerApiPath, dartServerApiCode, {
  encoding: "utf8",
  flag: "w",
});

chdir("./game");
execSync("dart format lib");
chdir("../admin");
execSync("npm run format");
console.log("Successfully wrote APIs!");

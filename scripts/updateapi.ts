import { genDartDtoFile } from "./updateapi-lib/dartgen";
import { getDtoDefinitions } from "./updateapi-lib/dtoscanner";
import { genTsDtoFile } from "./updateapi-lib/tsgen";
import { writeFileSync } from "fs";
import { execSync } from "child_process";

const flutterDtoPath = "./game/lib/api/game_client_dto.dart";
const adminDtoPath = "./admin/src/all.dto.ts";

const dtos = getDtoDefinitions();
const dartCode = genDartDtoFile(dtos);
const tsCode = genTsDtoFile(dtos);

writeFileSync(flutterDtoPath, dartCode, { encoding: "utf8", flag: "w" });
writeFileSync(adminDtoPath, tsCode, { encoding: "utf8", flag: "w" });

execSync("dart format " + flutterDtoPath);
execSync("npx prettier " + adminDtoPath);

console.log("Successfully wrote DTOs!");

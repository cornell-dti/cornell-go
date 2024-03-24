"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const dartgen_1 = require("./updateapi-lib/dartgen");
const dtoscanner_1 = require("./updateapi-lib/dtoscanner");
const tsgen_1 = require("./updateapi-lib/tsgen");
const fs_1 = require("fs");
const child_process_1 = require("child_process");
const flutterDtoPath = "./game/lib/api/game_client_dto.dart";
const adminDtoPath = "./admin/src/all.dto.ts";
const dtos = (0, dtoscanner_1.getDtoDefinitions)();
const dartCode = (0, dartgen_1.genDartDtoFile)(dtos);
const tsCode = (0, tsgen_1.genTsDtoFile)(dtos);
(0, fs_1.writeFileSync)(flutterDtoPath, dartCode, { encoding: "utf8", flag: "w" });
(0, fs_1.writeFileSync)(adminDtoPath, tsCode, { encoding: "utf8", flag: "w" });
(0, child_process_1.execSync)("dart format " + flutterDtoPath);
(0, child_process_1.execSync)("npx prettier " + adminDtoPath);
console.log("Successfully wrote DTOs!");
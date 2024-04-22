"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const fs_1 = require("fs");
const child_process_1 = require("child_process");
const process_1 = require("process");
const dartgen_1 = require("./updateapi-lib/dartgen");
const dtoscanner_1 = require("./updateapi-lib/dtoscanner");
const tsgen_1 = require("./updateapi-lib/tsgen");
const apiscanner_1 = require("./updateapi-lib/apiscanner");
const flutterDtoPath = "./game/lib/api/game_client_dto.dart";
const adminDtoPath = "./admin/src/all.dto.ts";
const flutterClientApiPath = "./game/lib/api/game_client_api.dart";
const flutterServerApiPath = "./game/lib/api/game_server_api.dart";
const adminApiPath = "./admin/src/components/ServerApi.tsx";
const dtos = (0, dtoscanner_1.getDtoDefinitions)();
const apis = (0, apiscanner_1.getApiDefinitions)();
const dartDtoCode = (0, dartgen_1.genDartDtoFile)(dtos);
const tsDtoCode = (0, tsgen_1.genTsDtoFile)(dtos);
const tsApiCode = (0, tsgen_1.getAdminApiFile)(apis);
const dartClientApiCode = (0, dartgen_1.getDartClientApiFile)(apis);
const dartServerApiCode = (0, dartgen_1.getDartServerApiFile)(apis);
(0, fs_1.writeFileSync)(flutterDtoPath, dartDtoCode, {
  encoding: "utf8",
  flag: "w",
});
(0, fs_1.writeFileSync)(adminDtoPath, tsDtoCode, {
  encoding: "utf8",
  flag: "w",
});
(0, fs_1.writeFileSync)(adminApiPath, tsApiCode, {
  encoding: "utf8",
  flag: "w",
});
(0, fs_1.writeFileSync)(flutterClientApiPath, dartClientApiCode, {
  encoding: "utf8",
  flag: "w",
});
(0, fs_1.writeFileSync)(flutterServerApiPath, dartServerApiCode, {
  encoding: "utf8",
  flag: "w",
});
(0, process_1.chdir)("./game");
(0, child_process_1.execSync)("dart format lib");
(0, process_1.chdir)("../admin");
(0, child_process_1.execSync)("npm run format");
console.log("Successfully wrote APIs!");

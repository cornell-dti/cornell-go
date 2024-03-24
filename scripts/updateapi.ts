import { genDartDtoFile } from "./updateapi-lib/dartgen";
import { getDtoDefinitions } from "./updateapi-lib/dtoscanner";
import { genTsDtoFile } from "./updateapi-lib/tsgen";

const flutterDtoPath = "./game/lib/api/game_client_dto.dart";
const adminDtoPath = "./admin/src/all.dto.ts";

const dtos = getDtoDefinitions();
const dartCode = genDartDtoFile(dtos);
const tsCode = genTsDtoFile(dtos);



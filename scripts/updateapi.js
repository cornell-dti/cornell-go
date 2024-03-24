"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const dartgen_1 = require("./updateapi-lib/dartgen");
const dtoscanner_1 = require("./updateapi-lib/dtoscanner");
const tsgen_1 = require("./updateapi-lib/tsgen");
const dtos = (0, dtoscanner_1.getDtoDefinitions)();
const dartCode = (0, dartgen_1.genDartDtoFile)(dtos);
const tsCode = (0, tsgen_1.genTsDtoFile)(dtos);
console.log(tsCode);

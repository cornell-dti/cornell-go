"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getDtoDefinitions = void 0;
const ts_morph_1 = require("ts-morph");
function getDtoDefinitions() {
    const project = new ts_morph_1.Project({});
    project.addSourceFilesAtPaths("server/src/*/*.dto.ts");
    console.log(`Discovered ${project.getSourceFiles().length} DTO files!`);
    console.log();
    const enumDtos = new Map();
    const baseDtos = new Map();
    for (const file of project.getSourceFiles()) {
        const interfs = file.getInterfaces();
        const enums = file.getEnums();
        console.log(`${file.getBaseName()}: ${enums.length} enums, ${interfs.length} DTOs`);
        for (const enum_ of enums) {
            const vals = enum_.getMembers().map((val) => val.getName());
            enumDtos.set(enum_.getName(), vals);
        }
        for (const interf of interfs) {
            const props = interf.getProperties();
            const baseDto = new Map();
            const interfName = interf.getName();
            baseDtos.set(interfName, baseDto);
            for (const prop of props) {
                const propType = prop.getType();
                const propName = prop.getName();
                const isOptional = prop.hasQuestionToken();
                if (propType.isString() || propType.getArrayElementType()?.isString()) {
                    // str
                    baseDto.set(propName, [
                        "string",
                        propType.isArray() ? "PRIMITIVE[]" : "PRIMITIVE",
                        isOptional,
                    ]);
                }
                else if (propType.isNumber() ||
                    propType.getArrayElementType()?.isNumber()) {
                    // num
                    baseDto.set(propName, [
                        "number",
                        propType.isArray() ? "PRIMITIVE[]" : "PRIMITIVE",
                        isOptional,
                    ]);
                }
                else if (propType.isBoolean() ||
                    propType.getArrayElementType()?.isBoolean()) {
                    // num
                    baseDto.set(propName, [
                        "boolean",
                        propType.isArray() ? "PRIMITIVE[]" : "PRIMITIVE",
                        isOptional,
                    ]);
                }
                else if (propType.isInterface() ||
                    propType.getArrayElementType()?.isInterface() ||
                    propType.isEnum() ||
                    propType.getArrayElementType()?.isEnum()) {
                    let name = propType.isArray()
                        ? propType.getArrayElementTypeOrThrow().getText()
                        : propType.getText();
                    const isEnum = propType.isEnum() || propType.getArrayElementType()?.isEnum();
                    if (name.includes(".")) {
                        name = name.split(".").pop();
                    }
                    const fieldType = propType.isArray()
                        ? isEnum
                            ? "ENUM_DTO[]"
                            : "DEPENDENT_DTO[]"
                        : isEnum
                            ? "ENUM_DTO"
                            : "DEPENDENT_DTO";
                    baseDto.set(propName, [name, fieldType, isOptional]);
                }
                else if (propType.isUnion() ||
                    propType.getArrayElementType()?.isUnion()) {
                    // enum
                    const enumName = interfName.replace("Dto", "") +
                        propName[0].toUpperCase() +
                        propName.substring(1) +
                        "Dto";
                    enumDtos.set(enumName, propType
                        .getUnionTypes()
                        .map((t) => t.getLiteralValue()?.toString() ?? ""));
                    baseDto.set(propName, [
                        enumName,
                        propType.isArray() ? "ENUM_DTO[]" : "ENUM_DTO",
                        isOptional,
                    ]);
                }
            }
        }
    }
    console.log();
    return { enumDtos, baseDtos };
}
exports.getDtoDefinitions = getDtoDefinitions;

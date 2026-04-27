"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getDtoDefinitions = getDtoDefinitions;
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
        // Count as const objects that qualify as enums
        let constEnumCount = 0;
        console.log(`${file.getBaseName()}: ${enums.length} enums, ${interfs.length} DTOs`);
        for (const enum_ of enums) {
            const vals = enum_.getMembers().map((val) => val.getName());
            enumDtos.set(enum_.getName(), vals);
        }
        // Support `as const` objects as enums:
        // const FooDto = { A: 'A', B: 'B' } as const;
        for (const varStmt of file.getVariableStatements()) {
            for (const decl of varStmt.getDeclarations()) {
                const init = decl.getInitializer();
                if (init?.getKind() === ts_morph_1.SyntaxKind.AsExpression) {
                    const inner = init.getChildAtIndex(0);
                    if (inner.getKind() === ts_morph_1.SyntaxKind.ObjectLiteralExpression) {
                        const name = decl.getName();
                        if (name.endsWith("Dto")) {
                            const props = inner
                                .asKindOrThrow(ts_morph_1.SyntaxKind.ObjectLiteralExpression)
                                .getProperties()
                                .filter((p) => p.getKind() === ts_morph_1.SyntaxKind.PropertyAssignment)
                                .map((p) => p.asKindOrThrow(ts_morph_1.SyntaxKind.PropertyAssignment).getName());
                            if (props.length > 0) {
                                enumDtos.set(name, props);
                                constEnumCount++;
                            }
                        }
                    }
                }
            }
        }
        if (constEnumCount > 0) {
            console.log(`  (also found ${constEnumCount} 'as const' enum${constEnumCount > 1 ? "s" : ""})`);
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
                    // bool
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
                    const unionTypes = propType.isArray()
                        ? propType.getArrayElementTypeOrThrow().getUnionTypes()
                        : propType.getUnionTypes();
                    // Filter out null/undefined from the union
                    const nonNullTypes = unionTypes.filter((t) => !t.isNull() && !t.isUndefined());
                    // Collect string literal values
                    const literalValues = nonNullTypes
                        .map((t) => t.getLiteralValue()?.toString())
                        .filter((v) => v !== undefined && v !== "");
                    if (literalValues.length > 0) {
                        // String literal union → generate enum (existing behavior)
                        const enumName = interfName.replace("Dto", "") +
                            propName[0].toUpperCase() +
                            propName.substring(1) +
                            "Dto";
                        enumDtos.set(enumName, literalValues);
                        baseDto.set(propName, [
                            enumName,
                            propType.isArray() ? "ENUM_DTO[]" : "ENUM_DTO",
                            isOptional,
                        ]);
                    }
                    else {
                        // Union of DTOs/objects (e.g. `FooDto | { id: string }`)
                        // Use the first named interface/enum type in the union
                        const namedType = nonNullTypes.find((t) => t.isInterface() || t.isEnum());
                        if (namedType) {
                            let name = namedType.getText();
                            if (name.includes("."))
                                name = name.split(".").pop();
                            const isEnum = namedType.isEnum();
                            const fieldType = propType.isArray()
                                ? isEnum
                                    ? "ENUM_DTO[]"
                                    : "DEPENDENT_DTO[]"
                                : isEnum
                                    ? "ENUM_DTO"
                                    : "DEPENDENT_DTO";
                            baseDto.set(propName, [name, fieldType, isOptional]);
                        }
                        else if (nonNullTypes.length === 1 && nonNullTypes[0].isNumber()) {
                            // number | null → treat as optional number
                            baseDto.set(propName, ["number", "PRIMITIVE", true]);
                        }
                        else if (nonNullTypes.length === 1 && nonNullTypes[0].isString()) {
                            // string | null → treat as optional string
                            baseDto.set(propName, ["string", "PRIMITIVE", true]);
                        }
                        else if (nonNullTypes.length === 1 && nonNullTypes[0].isBoolean()) {
                            // boolean | null → treat as optional boolean
                            baseDto.set(propName, ["boolean", "PRIMITIVE", true]);
                        }
                        // else: skip field entirely (can't represent it)
                    }
                }
            }
        }
    }
    console.log();
    return { enumDtos, baseDtos };
}

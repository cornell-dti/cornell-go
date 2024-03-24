"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.genTsDtoFile = void 0;
function genTsDtoFile(dtoDefs) {
    let tsCode = "";
    for (const [name, fields] of dtoDefs.enumDtos.entries()) {
        tsCode += `type ${name} =`;
        for (const field of fields) {
            tsCode += `\n  | "${field}"`;
        }
        tsCode += ";\n";
    }
    for (const [name, propMap] of dtoDefs.baseDtos.entries()) {
        tsCode += `export interface ${name} {\n`;
        for (const [propName, [typeName, fieldType, isOptional],] of propMap.entries()) {
            const isArray = fieldType == "ENUM_DTO[]" ||
                fieldType == "DEPENDENT_DTO[]" ||
                fieldType == "PRIMITIVE[]";
            const fullType = isArray ? `List<${typeName}>` : typeName;
            tsCode += `  ${propName}`;
            if (isOptional) {
                tsCode += "?";
            }
            tsCode += `: ${fullType};\n`;
        }
        tsCode += "}\n\n";
    }
    return tsCode;
}
exports.genTsDtoFile = genTsDtoFile;

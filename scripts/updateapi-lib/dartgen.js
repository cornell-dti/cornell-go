"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.genDartDtoFile = void 0;
function toDartType(tsType, tsName) {
    switch (tsType) {
        case "string":
            return "String";
        case "number":
            return tsName.endsWith("Float") || tsName.endsWith("F")
                ? "double"
                : "int";
        case "boolean":
            return "bool";
        default:
            return tsType;
    }
}
function genDartDtoFile(dtoDefs) {
    let dartCode = "// CODE AUTOGENERATED BY npm run updateapi\n";
    for (const [name, fields] of dtoDefs.enumDtos.entries()) {
        dartCode += `enum ${name} {\n`;
        for (const field of fields) {
            dartCode += `  ${field},\n`;
        }
        dartCode += "}\n\n";
    }
    for (const [name, propMap] of dtoDefs.baseDtos.entries()) {
        dartCode += `class ${name} {\n`;
        dartCode += `  Map<String, dynamic> toJson() {\n`;
        dartCode += `    Map<String, dynamic> fields = {};\n`;
        for (const [propName, [typeName, fieldType, isOptional],] of propMap.entries()) {
            const dartType = toDartType(typeName, propName);
            if (isOptional) {
                dartCode += `  if (${propName} != null) {\n      `;
            }
            dartCode += `    fields['${propName}'] = `;
            if (fieldType == "PRIMITIVE" && dartType == "double") {
                dartCode += `${propName}!.toDouble()`;
            }
            else if (fieldType == "PRIMITIVE[]" && dartType == "double") {
                dartCode += `
            ${propName}!
              .map<Map<String, dynamic>>(
                (dynamic val) => val!.toDouble()
              ).toList()
        `;
            }
            else if (fieldType == "PRIMITIVE" || fieldType == "PRIMITIVE[]") {
                dartCode += `${propName}`;
            }
            else if (fieldType == "DEPENDENT_DTO") {
                dartCode += `${propName}!.toJson()`;
            }
            else if (fieldType == "DEPENDENT_DTO[]") {
                dartCode += `
            ${propName}!
              .map<Map<String, dynamic>>(
                (dynamic val) => val!.toJson()
              ).toList()
        `;
            }
            else if (fieldType == "ENUM_DTO") {
                dartCode += `${propName}!.toString()`;
            }
            else if (fieldType == "ENUM_DTO[]") {
                dartCode += `
            ${propName}!
              .map<String>(
                (dynamic val) => val!.toString()
              ).toList()
        `;
            }
            if (isOptional) {
                dartCode += `;\n    }\n`;
            }
            else {
                dartCode += ";\n";
            }
        }
        dartCode += "    return fields;\n";
        dartCode += "  }\n\n";
        dartCode += `  ${name}.fromJson(Map<String, dynamic> fields) {\n`;
        for (const [propName, [typeName, fieldType, isOptional],] of propMap.entries()) {
            const dartType = toDartType(typeName, propName);
            dartCode += `    ${propName} = `;
            if (isOptional) {
                dartCode += `fields.containsKey('${propName}') ? (\n      `;
            }
            if (fieldType == "PRIMITIVE") {
                dartCode += `fields["${propName}"]`;
            }
            else if (fieldType == "PRIMITIVE[]") {
                dartCode += `List<${dartType}>.from(fields['${propName}'])`;
            }
            else if (fieldType == "DEPENDENT_DTO") {
                dartCode += `${dartType}.fromJson(fields['${propName}'])`;
            }
            else if (fieldType == "DEPENDENT_DTO[]") {
                dartCode += `
          fields["${propName}"]
            .map<${dartType}>(
              (dynamic val) => ${dartType}.fromJson(val)
            ).toList()
        `;
            }
            else if (fieldType == "ENUM_DTO") {
                dartCode += `${dartType}.values.byName(fields['${propName}'])`;
            }
            else if (fieldType == "ENUM_DTO[]") {
                dartCode += `
            fields["${propName}"]
              .map<${dartType}>(
                (dynamic val) => ${dartType}.values.byName(val)
              ).toList()
        `;
            }
            if (isOptional) {
                dartCode += `\n    ) : null;\n`;
            }
            else {
                dartCode += ";\n";
            }
        }
        dartCode += "  }\n\n";
        dartCode += `  void partialUpdate(${name} other) {`;
        for (const [propName, [_, __, isOptional]] of propMap.entries()) {
            if (isOptional) {
                dartCode += `    ${propName} = other.${propName} == null ? ${propName} : other.${propName};\n`;
            }
            else {
                dartCode += `    ${propName} = other.${propName};\n`;
            }
        }
        dartCode += "  }\n\n";
        for (const [propName, [typeName, fieldType, isOptional],] of propMap.entries()) {
            const dartType = toDartType(typeName, propName);
            const isArray = fieldType == "ENUM_DTO[]" ||
                fieldType == "DEPENDENT_DTO[]" ||
                fieldType == "PRIMITIVE[]";
            const fullType = isArray ? `List<${dartType}>` : dartType;
            dartCode += `  late ${fullType}`;
            if (isOptional) {
                dartCode += "?";
            }
            dartCode += ` ${propName};\n`;
        }
        dartCode += "}\n\n";
    }
    return dartCode;
}
exports.genDartDtoFile = genDartDtoFile;

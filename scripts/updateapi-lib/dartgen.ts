import { DtoDefs } from "./types";

function toDartType(tsType: string, tsName: string) {
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

export function genDartDtoFile(dtoDefs: DtoDefs) {
  let dartCode = "";

  for (const [name, fields] of dtoDefs.enumDtos.entries()) {
    dartCode += `enum ${name} {\n`;
    for (const field of fields) {
      dartCode += `  ${field},\n`;
    }
    dartCode += "}\n\n";
  }

  for (const [name, propMap] of dtoDefs.baseDtos.entries()) {
    dartCode += `class ${name} {\n`;
    dartCode += `  ${name}.fromJson(Map<String, dynamic> fields) {\n`;
    for (const [
      propName,
      [typeName, fieldType, isOptional],
    ] of propMap.entries()) {
      const dartType = toDartType(typeName, propName);
      dartCode += `    ${propName} = `;
      if (isOptional) {
        dartCode += `fields['${propName}'] ? (\n      `;
      }
      if (fieldType == "PRIMITIVE") {
        dartCode += `fields["${propName}"]`;
      } else if (fieldType == "PRIMITIVE[]") {
        dartCode += `List<${dartType}>.from(fields['${propName}'])`;
      } else if (fieldType == "DEPENDENT_DTO") {
        dartCode += `${dartType}.fromJson(fields['${propName}'])`;
      } else if (fieldType == "DEPENDENT_DTO[]") {
        dartCode += `
          fields["${propName}"]
            .map<${dartType}>(
              (dynamic val) => ${dartType}.fromJson(val))
          .toList();
        `;
      } else if (fieldType == "ENUM_DTO") {
        dartCode += `${dartType}.values.byName(fields['${propName}'])`;
      } else if (fieldType == "ENUM_DTO[]") {
        dartCode += `
            fields["${propName}"]
              .map<${dartType}>(
                (dynamic val) => ${dartType}.values.byName(val))
            .toList()
        `;
      }
      if (isOptional) {
        dartCode += `\n    ) : null;\n`;
      } else {
        dartCode += ";\n";
      }
    }
    dartCode += "  }\n\n";

    for (const [
      propName,
      [typeName, fieldType, isOptional],
    ] of propMap.entries()) {
      const dartType = toDartType(typeName, propName);
      const isArray =
        fieldType == "ENUM_DTO[]" ||
        fieldType == "DEPENDENT_DTO[]" ||
        fieldType == "PRIMITIVE[]";

      const fullType = isArray ? `List<${dartType}>` : dartType;

      dartCode += `  ${fullType}`;
      if (isOptional) {
        dartCode += "?";
      }
      dartCode += ` ${propName};\n`;
    }

    dartCode += "}\n\n";
  }

  return dartCode;
}

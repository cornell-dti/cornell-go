import { Project } from "ts-morph";
const project = new Project({});

project.addSourceFilesAtPaths("server/src/*/*.dto.ts");

console.log("Found the following DTO files!");
console.log(project.getSourceFiles().map((file) => file.getBaseName()));

type FieldType =
  | "DEPENDENT_DTO"
  | "DEPENDENT_DTO[]"
  | "PRIMITIVE"
  | "PRIMITIVE[]";

type EnumDto = string[];
type BaseDto = Map<string, [string, FieldType]>;

const enumDtos = new Map<String, EnumDto>();
const baseDtos = new Map<String, BaseDto>();

for (const file of project.getSourceFiles()) {
  const interfs = file.getInterfaces();
  const enums = file.getEnums();

  for (const enum_ of enums) {
    const vals = enum_.getMembers().map((val) => val.getName());
    enumDtos.set(enum_.getName(), vals);
  }

  for (const interf of interfs) {
    const props = interf.getProperties();
    const baseDto = new Map<string, [string, FieldType]>();
    const interfName = interf.getName();
    baseDtos.set(interfName, baseDto);

    for (const prop of props) {
      const propType = prop.getType();
      const propName = prop.getName();
      const optPropName = prop.getName() + (prop.hasQuestionToken() ? "?" : "");

      if (propType.isString() || propType.getArrayElementType()?.isString()) {
        // str
        baseDto.set(optPropName, [
          "string",
          propType.isArray() ? "PRIMITIVE[]" : "PRIMITIVE",
        ]);
      } else if (
        propType.isNumber() ||
        propType.getArrayElementType()?.isNumber()
      ) {
        // num
        baseDto.set(optPropName, [
          "number",
          propType.isArray() ? "PRIMITIVE[]" : "PRIMITIVE",
        ]);
      } else if (
        propType.isBoolean() ||
        propType.getArrayElementType()?.isBoolean()
      ) {
        // num
        baseDto.set(optPropName, [
          "boolean",
          propType.isArray() ? "PRIMITIVE[]" : "PRIMITIVE",
        ]);
      } else if (
        propType.isUnion() ||
        propType.getArrayElementType()?.isUnion()
      ) {
        // enum
        const enumName =
          interfName.replace("Dto", "") +
          propName[0].toUpperCase() +
          propName.substring(1) +
          "Dto";

        enumDtos.set(
          enumName,
          propType
            .getUnionTypes()
            .map((t) => t.getLiteralValue()?.toString() ?? "")
        );

        baseDto.set(optPropName, [
          enumName,
          propType.isArray() ? "DEPENDENT_DTO[]" : "DEPENDENT_DTO",
        ]);
      } else if (
        propType.isInterface() ||
        propType.getArrayElementType()?.isInterface() ||
        propType.isEnum() ||
        propType.getArrayElementType()?.isEnum()
      ) {
        let name = propType.isArray()
          ? propType.getArrayElementTypeOrThrow().getText()
          : propType.getText();

        if (name.includes(".")) {
          name = name.split(".").pop()!;
        }

        baseDto.set(optPropName, [
          name,
          propType.isArray() ? "DEPENDENT_DTO[]" : "DEPENDENT_DTO",
        ]);
      }
    }
  }
}

let dartCode = "";
let tsCode = "";

export type FieldType =
  | "ENUM_DTO"
  | "ENUM_DTO[]"
  | "DEPENDENT_DTO"
  | "DEPENDENT_DTO[]"
  | "PRIMITIVE"
  | "PRIMITIVE[]";

export type EnumDto = string[];
// fieldName => [typename, fieldtype, isOptional]
export type BaseDto = Map<string, [string, FieldType, boolean]>;

export type DtoDefs = {
  enumDtos: Map<String, EnumDto>;
  baseDtos: Map<String, BaseDto>;
};

export type ApiDefs = {
  clientEntrypoints: Map<String, String>; // message => dto
  serverEntrypoints: Map<String, String>; // message => dto
};

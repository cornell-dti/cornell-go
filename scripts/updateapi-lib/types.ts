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
  enumDtos: Map<string, EnumDto>;
  baseDtos: Map<string, BaseDto>;
};

export type ApiDefs = {
  clientEntrypoints: Map<string, string>; // message => dto
  serverEntrypoints: Map<string, string>; // message => dto
  serverAcks: Map<string, string>; // message => ack primitive type
};

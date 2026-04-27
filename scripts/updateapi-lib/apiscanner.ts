import { ObjectLiteralElement, Project, SyntaxKind } from "ts-morph";
import { ApiDefs } from "./types";

export function getApiDefinitions() {
  const project = new Project({});

  project.addSourceFilesAtPaths("server/src/*/*.gateway.ts");
  project.addSourceFilesAtPaths("server/src/*/*.dto.ts");
  project.addSourceFileAtPath("server/src/client/client.service.ts");

  const apiDefs: ApiDefs = {
    serverEntrypoints: new Map(),
    serverAcks: new Map(),
    clientEntrypoints: new Map(),
  };

  const clientFile = project.getSourceFileOrThrow("client.service.ts");
  const clientApiDef = clientFile.getTypeAliasOrThrow("ClientApiDef");

  for (const prop of clientApiDef.getType().getProperties()) {
    const ev = prop.getValueDeclarationOrThrow().getChildAtIndex(0).getText();
    const dto = prop.getValueDeclarationOrThrow().getChildAtIndex(2).getText();

    // Skip inline object types like { event: CampusEventDto }
    if (dto.startsWith("{")) {
      console.log(
        `Client event "${ev}" uses inline object type — skipping. Use a named DTO instead.`
      );
      continue;
    }

    apiDefs.clientEntrypoints.set(ev, dto);
  }

  console.log(`Processed ${apiDefs.clientEntrypoints.size} client functions!`);
  console.log();

  for (const file of project.getSourceFiles("server/src/*/*.gateway.ts")) {
    for (const _class of file.getClasses()) {
      const funcs = _class
        .getMethods()
        .filter((met) => !!met.getDecorator("SubscribeMessage"));

      if (!_class.getName()?.includes("Gateway")) continue;
      console.log(`${file.getBaseName()}: ${funcs.length} message functions`);

      if (funcs.length === 0) continue;

      for (const func of funcs) {
        const ev = func
          .getDecoratorOrThrow("SubscribeMessage")
          .getArguments()[0]
          .asKindOrThrow(SyntaxKind.StringLiteral)
          .getLiteralValue();

        const messageBodyParam = func
          .getParameters()
          .find((param) => !!param.getDecorator("MessageBody"));

        let dto = "";
        if (messageBodyParam) {
          dto = messageBodyParam.getType().getText();
        }

        // Strip intersection types: "FooDto & { id: string; }" → "FooDto"
        if (dto.includes("&")) {
          const base = dto.split("&")[0].trim();
          console.log(
            `Function ${ev} uses intersection type, using base type: ${base}`
          );
          dto = base;
        }

        // Strip utility types: "Omit<FooDto, "id">" → "FooDto"
        // ts-morph may resolve to full path like: Omit<import("...").SpotlightDto, "id">
        const utilityMatch = dto.match(
          /^(?:Omit|Pick|Partial|Required)<(?:import\([^)]*\)\.)?(\w+)/
        );
        if (utilityMatch) {
          console.log(
            `Function ${ev} uses utility type, using base type: ${utilityMatch[1]}`
          );
          dto = utilityMatch[1];
        }

        if (!func.getReturnType().getText().startsWith("Promise")) {
          console.log(
            `Function ${ev} does not return a promise/is not async! Skipping...`
          );
          continue;
        }

        let ackType = func.getReturnType().getTypeArguments()[0];

        if (ackType.isUnion() && !ackType.isBoolean() && !ackType.isNumber()) {
          const unionTypes = ackType.getUnionTypes();
          if (unionTypes.length > 2) {
            console.log(
              `Function ${ev} has more than 1 union type! Must be in the form <number|boolean|string> | <undefined | null>! Skipping...`
            );
            continue;
          }

          ackType =
            unionTypes[0].isNull() || unionTypes[0].isUndefined()
              ? unionTypes[1]
              : unionTypes[0];
        }

        if (
          !(ackType.isString() || ackType.isNumber() || ackType.isBoolean())
        ) {
          // Use "dynamic" for complex return types instead of skipping
          apiDefs.serverAcks.set(ev, "dynamic");
        } else {
          apiDefs.serverAcks.set(ev, ackType.getText());
        }

        if (dto.includes(".")) {
          dto = dto.split(".").pop()!;
        }

        apiDefs.serverEntrypoints.set(ev, dto);
      }

      break;
    }
  }

  console.log();
  console.log(`Processed ${apiDefs.serverEntrypoints.size} server functions!`);
  console.log();

  return apiDefs;
}

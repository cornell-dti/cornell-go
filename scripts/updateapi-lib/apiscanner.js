"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getApiDefinitions = void 0;
const ts_morph_1 = require("ts-morph");
function getApiDefinitions() {
    const project = new ts_morph_1.Project({});
    project.addSourceFilesAtPaths("server/src/*/*.gateway.ts");
    project.addSourceFilesAtPaths("server/src/*/*.dto.ts");
    project.addSourceFileAtPath("server/src/client/client.service.ts");
    const apiDefs = {
        serverEntrypoints: new Map(),
        serverAcks: new Map(),
        clientEntrypoints: new Map(),
    };
    const clientFile = project.getSourceFileOrThrow("client.service.ts");
    const clientApiDef = clientFile.getTypeAliasOrThrow("ClientApiDef");
    for (const prop of clientApiDef.getType().getProperties()) {
        const ev = prop.getValueDeclarationOrThrow().getChildAtIndex(0).getText();
        const dto = prop.getValueDeclarationOrThrow().getChildAtIndex(2).getText();
        apiDefs.clientEntrypoints.set(ev, dto);
    }
    console.log(`Processed ${apiDefs.clientEntrypoints.size} client functions!`);
    console.log();
    for (const file of project.getSourceFiles("server/src/*/*.gateway.ts")) {
        for (const _class of file.getClasses()) {
            const funcs = _class
                .getMethods()
                .filter((met) => !!met.getDecorator("SubscribeMessage"));
            if (!_class.getName()?.includes("Gateway"))
                continue;
            console.log(`${file.getBaseName()}: ${funcs.length} message functions`);
            if (funcs.length === 0)
                continue;
            for (const func of funcs) {
                const ev = func
                    .getDecoratorOrThrow("SubscribeMessage")
                    .getArguments()[0]
                    .asKindOrThrow(ts_morph_1.SyntaxKind.StringLiteral)
                    .getLiteralValue();
                let dto = func
                    .getParameterOrThrow((param) => !!param.getDecorator("MessageBody"))
                    .getType()
                    .getText();
                if (!func.getReturnType().getText().startsWith("Promise")) {
                    console.log(`Function ${ev} does not return a promise/is not async! Skipping...`);
                    continue;
                }
                let ackType = func.getReturnType().getTypeArguments()[0];
                if (ackType.isUnion() && !ackType.isBoolean() && !ackType.isNumber()) {
                    const unionTypes = ackType.getUnionTypes();
                    if (unionTypes.length > 2) {
                        console.log(`Function ${ev} has more than 1 union type! Must be in the form <number|boolean|string> | <undefined | null>! Skipping...`);
                        continue;
                    }
                    ackType =
                        unionTypes[0].isNull() || unionTypes[0].isUndefined()
                            ? unionTypes[1]
                            : unionTypes[0];
                }
                if (!(ackType.isString() || ackType.isNumber() || ackType.isBoolean())) {
                    console.log(`Function ${ev} does not return one of number, boolean, or string! Skipping...`);
                    continue;
                }
                apiDefs.serverAcks.set(ev, ackType.getText());
                if (dto.includes(".")) {
                    dto = dto.split(".").pop();
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
exports.getApiDefinitions = getApiDefinitions;

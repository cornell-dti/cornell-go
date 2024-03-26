"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getDartServerApiFile = exports.getDartClientApiFile = exports.genDartDtoFile = void 0;
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
                dartCode += `${propName}!.name`;
            }
            else if (fieldType == "ENUM_DTO[]") {
                dartCode += `
            ${propName}!
              .map<String>(
                (dynamic val) => val!.name
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
        dartCode += `  ${name}(`;
        for (const propName of propMap.keys()) {
            dartCode += `\nthis.${propName}, `;
        }
        dartCode += "  );\n\n";
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
function getDartClientApiFile(apiDefs) {
    let dartCode = `
  // CODE AUTOGENERATED BY npm run updateapi

  import 'dart:async';

  import 'package:game/api/game_client_dto.dart';
  import 'package:socket_io_client/socket_io_client.dart';

  class GameClientApi {
  `;
    for (const [ev, dto] of apiDefs.clientEntrypoints.entries()) {
        dartCode += `
      final _${ev}Controller =
        StreamController<${dto}>.broadcast(sync: true);
      Stream<${dto}> get ${ev}Stream =>
          _${ev}Controller.stream;

    `;
    }
    dartCode += `
    final _reconnectedController = StreamController<Null>.broadcast(sync: true);
    Stream<Null> get reconnectedStream => _reconnectedController.stream;

    final _reconnectingController = StreamController<Null>.broadcast(sync: true);
    Stream<Null> get reconnectingStream => _reconnectingController.stream;

    final _connectedController = StreamController<Null>.broadcast(sync: true);
    Stream<Null> get connectedStream => _connectedController.stream;

    final disconnectedController = StreamController<Null>.broadcast(sync: true);
    Stream<Null> get disconnectedStream => disconnectedController.stream;

    void connectSocket(Socket sock) {
      sock.onReconnect((data) => _reconnectingController.add(null));
      sock.onReconnecting((data) => _reconnectedController.add(null));
      sock.onDisconnect((data) => disconnectedController.add(null));

  `;
    for (const [ev, dto] of apiDefs.clientEntrypoints.entries()) {
        dartCode += `
      sock.on(
        "${ev}",
        (data) =>
            _${ev}Controller.add(${dto}.fromJson(data)));

    `;
    }
    dartCode += `
      _connectedController.add(null);
    }

    GameClientApi() {}
  }
  `;
    return dartCode;
}
exports.getDartClientApiFile = getDartClientApiFile;
function getDartServerApiFile(apiDefs) {
    let dartCode = `
  // CODE AUTOGENERATED BY npm run updateapi

  import 'dart:async';
  import 'dart:convert';
  import 'package:game/api/game_client_dto.dart';
  import 'package:socket_io_client/socket_io_client.dart';
  
  class GameServerApi {
    final Future<bool> Function() _refreshAccess;
    Socket _socket;
  
    String _refreshEv = "";
    dynamic _refreshDat = "";
  
    GameServerApi(Socket socket, Future<bool> Function() refresh)
        : _refreshAccess = refresh,
          _socket = socket {
      _socket.onError((data) async {
        if (await _refreshAccess()) {
          _socket.emit(_refreshEv, _refreshDat);
        }
      });
    }
  
    void replaceSocket(Socket socket) {
      _socket = socket;
      _socket.onError((data) async {
        if (await _refreshAccess()) {
          _socket.emit(_refreshEv, _refreshDat);
        }
      });
    }
  
    void _invokeWithRefresh(String ev, Map<String, dynamic> data) {
      _refreshEv = ev;
      _refreshDat = data;
      print(ev);
      _socket.emit(ev, data);
    }
  `;
    for (const [ev, dto] of apiDefs.serverEntrypoints.entries()) {
        dartCode += `
      void ${ev}(${dto} dto) => _invokeWithRefresh(
        "${ev}", dto.toJson());

    `;
    }
    dartCode += "}";
    return dartCode;
}
exports.getDartServerApiFile = getDartServerApiFile;

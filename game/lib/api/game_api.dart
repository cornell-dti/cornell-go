import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:game/api/game_client_api.dart';
import 'package:game/api/game_server_api.dart';
import 'package:game/api/geopoint.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

class ApiClient extends ChangeNotifier {
  final FlutterSecureStorage _storage;

  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );

  final String _apiUrl;
  final Uri _googleLoginUrl;
  final Uri _deviceLoginUrl;
  final Uri _refreshUrl;
  final GameClientApi _clientApi;

  IO.Socket? _socket;
  String? _refreshToken;
  String? _accessToken;
  GameServerApi? _serverApi;

  GameClientApi get clientApi => _clientApi;
  GameServerApi? get serverApi => _serverApi;
  bool connectionFailed = false;
  bool authenticated = false;

  ApiClient(FlutterSecureStorage storage, String apiUrl)
      : _storage = storage,
        _apiUrl = apiUrl,
        _googleLoginUrl = Uri.parse(apiUrl + "/google"),
        _deviceLoginUrl = Uri.parse(apiUrl + "/device-login"),
        _refreshUrl = Uri.parse(apiUrl + "/refresh-access"),
        _clientApi = GameClientApi();

  void _createSocket(bool refreshing) async {
    if (_socket != null && !refreshing || _accessToken == null) return;

    if (refreshing && _socket != null) {
      _socket?.disconnect();
    }

    final socket = IO.io(
        _apiUrl,
        IO.OptionBuilder()
            .setTransports(["websocket"])
            .disableAutoConnect()
            .setAuth({'token': _accessToken})
            .build());

    socket.onDisconnect((data) {
      _serverApi = null;
      notifyListeners();
    });
    socket.onConnect((data) {
      _socket = socket;

      if (refreshing) {
        _serverApi?.replaceSocket(socket);
      } else {
        _serverApi = GameServerApi(socket, _accessRefresher);
      }
      _clientApi.connectSocket(socket);

      notifyListeners();
    });
    socket.onConnectError((data) {
      connectionFailed = true;
      notifyListeners();
    });
    socket.connect();
  }

  Future<bool> _accessRefresher() async {
    final refreshResult = await _refreshAccess(false);
    if (refreshResult) {
      authenticated = true;
      _createSocket(true);
    } else {
      authenticated = false;
      _clientApi.disconnectedController.add(null);
      _socket?.disconnect();
      _socket = null;
      notifyListeners();
    }
    return refreshResult;
  }

  Future<bool> _refreshAccess(bool relog) async {
    if (_refreshToken != null) {
      final refreshResponse =
          await http.post(_refreshUrl, body: {'refreshToken': _refreshToken});

      if (refreshResponse.statusCode == 201 && refreshResponse.body != "") {
        final responseBody = jsonDecode(refreshResponse.body);
        _accessToken = responseBody["accessToken"];
        _createSocket(!relog);

        return true;
      }
    }
    return false;
  }

  Future<void> _saveToken() async {
    if (_refreshToken != null) {
      await _storage.write(key: "refresh_token", value: _refreshToken);
    }
  }

  Future<bool> tryRelog() async {
    final token = await _storage.read(key: "refresh_token");

    if (token != null) {
      _refreshToken = token;

      final access = await _refreshAccess(true);
      authenticated = access;

      if (!access) {
        _clientApi.disconnectedController.add(null);
      }
      notifyListeners();
      return access;
    }

    authenticated = false;
    _clientApi.disconnectedController.add(null);
    notifyListeners();
    return false;
  }

  Future<bool> _connect(String idToken, Uri url) async {
    final pos = await GeoPoint.current();

    final loginResponse = await http.post(url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          "idToken": idToken,
          "lat": pos.lat.toString(),
          "long": pos.long.toString(),
          "aud": Platform.isIOS ? "ios" : "android"
        }));

    if (loginResponse.statusCode == 201 && loginResponse.body != "") {
      final responseBody = jsonDecode(loginResponse.body);

      this._accessToken = responseBody["accessToken"];
      this._refreshToken = responseBody["refreshToken"];

      await _saveToken();

      _createSocket(false);
      return true;
    }

    authenticated = false;
    _clientApi.disconnectedController.add(null);
    notifyListeners();
    return false;
  }

  Future<bool> connectId(String id) async {
    return _connect(id, _deviceLoginUrl);
  }

  Future<bool> connectGoogle() async {
    final account = await _googleSignIn.signIn();

    if (account != null) {
      final auth = await account.authentication;
      final idToken = auth.idToken!;

      return _connect(idToken, _googleLoginUrl);
    }
    authenticated = false;
    _clientApi.disconnectedController.add(null);
    notifyListeners();
    return false;
  }

  Future<void> disconnect() async {
    await _storage.write(key: "refresh_token", value: "");
    await _googleSignIn.signOut();

    _refreshToken = null;
    _accessToken = null;

    _socket?.disconnect();
    _socket = null;

    authenticated = false;
    _clientApi.disconnectedController.add(null);
    notifyListeners();
  }
}

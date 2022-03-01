import 'dart:convert';

import 'package:game/api/game_client_api.dart';
import 'package:game/api/game_server_api.dart';
import 'package:game/api/geopoint.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

class ApiClient {
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

  ApiClient(FlutterSecureStorage storage, String apiUrl)
      : _storage = storage,
        _apiUrl = apiUrl,
        _googleLoginUrl = Uri.parse(apiUrl + "/google"),
        _deviceLoginUrl = Uri.parse(apiUrl + "/device-login"),
        _refreshUrl = Uri.parse(apiUrl + "/refresh-access"),
        _clientApi = GameClientApi();

  Future<bool> _createSocket() async {
    if (_socket != null) return true;
    if (_accessToken == null) return false;

    final socket = IO.io(
        _apiUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']).setAuth({'token': _accessToken}));

    if (socket.connected) {
      _socket = socket;
      _clientApi.connectSocket(socket);
      _serverApi = GameServerApi(socket, _refreshAccess);
      socket.onDisconnect((data) => _serverApi = null);
      return true;
    }

    return false;
  }

  Future<bool> _refreshAccess() async {
    if (_refreshToken != null) {
      final refreshResponse =
          await http.post(_refreshUrl, body: {'refreshToken': _refreshToken});

      if (refreshResponse.statusCode == 200 && refreshResponse.body != "null") {
        final responseBody = jsonDecode(refreshResponse.body);
        _accessToken = responseBody["accessToken"];

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
      return await _refreshAccess();
    }
    return false;
  }

  Future<bool> connectGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account != null) {
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final pos = await GeoPoint.current();
      final loginResponse = await http.post(_googleLoginUrl,
          body: {'idToken': idToken, 'lat': pos.lat, 'long': pos.long});

      if (loginResponse.statusCode == 200 && loginResponse.body != "null") {
        final responseBody = jsonDecode(loginResponse.body);

        this._accessToken = responseBody["accessToken"];
        this._refreshToken = responseBody["refreshToken"];

        await _saveToken();

        return await _createSocket();
      }
    }
    return false;
  }

  Future<bool> connectDevice(String id) async {
    final pos = await GeoPoint.current();
    final loginResponse = await http.post(_deviceLoginUrl,
        body: {'idToken': id, 'lat': pos.lat, 'long': pos.long});

    if (loginResponse.statusCode == 200 && loginResponse.body != "null") {
      final responseBody = jsonDecode(loginResponse.body);
      this._accessToken = responseBody["accessToken"];
      this._refreshToken = responseBody["refreshToken"];

      await _saveToken();

      return await _createSocket();
    }
    return false;
  }

  Future<void> disconnect() async {
    await _googleSignIn.signOut();
    _refreshToken = null;
    _accessToken = null;
  }
}

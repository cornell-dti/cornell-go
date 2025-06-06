import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:game/api/game_client_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/api/game_server_api.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:game/api/geopoint.dart';

/** 
 * ApiClient Class - Core authentication and API communication manager.
 * 
 * A ChangeNotifier class that manages authentication state, socket connections,
 * and API communication for the entire application.
 * 
 * @remarks
 * This class serves as the central hub for all API-related functionality:
 * - Authentication state management (Google Sign-In, device login)
 * - Socket connection handling and management
 * - Token management (access and refresh tokens)
 * - Stream management through GameClientApi
 * - Server API access through GameServerApi
 * 
 * The class uses a multi-layered approach:
 * - ApiClient: Top-level manager and state coordinator
 * - GameClientApi: Manages streams for UI updates
 * - GameServerApi: Handles server-side communication
 * 
 * Key Features:
 * - Automatic token refresh
 * - Persistent authentication through secure storage
 * - Socket connection management
 * - Google Sign-In integration
 * - Device-based authentication
 * 
 * @example
 * ```dart
 * final apiClient = Provider.of<ApiClient>(context);
 * 
 * // Listen to connection state
 * StreamBuilder(
 *   stream: apiClient.clientApi.disconnectedStream,
 *   builder: (context, snapshot) {
 *     // Handle connection state changes
 *   }
 * );
 * 
 * // Perform authentication
 * await apiClient.connectGoogle(googleAccount, ...);
 * ```
 * 
 * @see GameClientApi for stream management
 * @see GameServerApi for server communication
 */

class ApiClient extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );

  // The ApiClient manages the socket and authentication state while the ClientApi manages the streams that components listen to
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
        _googleLoginUrl = Uri.parse(apiUrl).resolve("google"),
        _deviceLoginUrl = Uri.parse(apiUrl).resolve("device-login"),
        _refreshUrl = Uri.parse(apiUrl).resolve("refresh-access"),
        _clientApi = GameClientApi();

  void _createSocket(bool refreshing) async {
    if (_socket != null && !refreshing || _accessToken == null) return;

    if (refreshing && _socket != null) {
      _socket?.destroy();
    }

    IO.cache.clear();
    final socket = IO.io(
        _apiUrl,
        IO.OptionBuilder()
            .setTransports(["websocket"])
            .disableAutoConnect()
            .setAuth({'token': _accessToken})
            .build());

    socket.onDisconnect((data) {
      print("Server Disconnected!");
      // Check if user is logged out
      if (_refreshToken == null) {
        _serverApi = null;
        notifyListeners();
      }
    });

    socket.onReconnectFailed((_) async {
      // Try to reconnect
      final refreshResult = await _accessRefresher();
      if (!refreshResult) {
        _serverApi = null;
      }
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
      _socket?.dispose();
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
      notifyListeners();
      return access;
    }

    authenticated = false;
    notifyListeners();
    return false;
  }

  Future<http.Response?> connectDevice(
      String year,
      LoginEnrollmentTypeDto enrollmentType,
      String username,
      String college,
      String major,
      List<String> interests) async {
    final String? id = await getId();
    return connect(id!, _deviceLoginUrl, year, enrollmentType, username,
        college, major, interests,
        noRegister: false);
  }

  Future<http.Response?> connectGoogle(
      GoogleSignInAccount gAccount,
      String year,
      LoginEnrollmentTypeDto enrollmentType,
      String username,
      String college,
      String major,
      List<String> interests) async {
    final auth = await gAccount.authentication;
    return connect(auth.idToken ?? "", _googleLoginUrl, year, enrollmentType,
        username, college, major, interests,
        noRegister: false);
  }

  Future<http.Response?> connectGoogleNoRegister(
      GoogleSignInAccount gAccount) async {
    final auth = await gAccount.authentication;
    return connect(auth.idToken ?? "", _googleLoginUrl, "",
        LoginEnrollmentTypeDto.GUEST, "", "", "", [],
        noRegister: true);
  }

  Future<http.Response?> connect(
      String idToken,
      Uri url,
      String year,
      LoginEnrollmentTypeDto enrollmentType,
      String username,
      String college,
      String major,
      List<String> interests,
      {bool noRegister = false}) async {
    final pos = await GeoPoint.current();

    final loginDto = LoginDto(
        idToken: idToken,
        latF: pos.lat,
        enrollmentType: enrollmentType,
        year: year,
        username: username,
        college: college,
        major: major,
        interests: interests.join(","),
        longF: pos.long,
        aud: Platform.isIOS ? LoginAudDto.ios : LoginAudDto.android,
        noRegister: noRegister);
    /*
    if (post != null) { */
    final loginResponse = await http.post(url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(loginDto.toJson()));

    if (loginResponse.statusCode == 201 && loginResponse.body != "") {
      final responseBody = jsonDecode(loginResponse.body);
      this._accessToken = responseBody["accessToken"];
      this._refreshToken = responseBody["refreshToken"];
      await _saveToken();
      _createSocket(false);
      return loginResponse;
    } else {
      print("LoginResponse:" + loginResponse.body);

      authenticated = false;
      notifyListeners();

      print("Failed to connect to server!");
      return null;
    }
    /*
    }
    print("Failed to get location data!");
    return null;
    */
  }

  Future<GoogleSignInAccount?> signinGoogle() async {
    final account = await _googleSignIn.signIn();
    return account;
  }

  Future<void> disconnect() async {
    await _storage.delete(key: "refresh_token");
    await _googleSignIn.signOut();

    _refreshToken = null;
    _accessToken = null;

    _socket?.dispose();
    _socket = null;

    authenticated = false;
    notifyListeners();
  }

  Future<bool> checkUserExists(String idToken) async {
    try {
      final uri = _googleLoginUrl.replace(
        path: '${_googleLoginUrl.path}/check-user',
        queryParameters: {'idToken': idToken},
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['exists'];
      }
      print('Failed to check user. Status code: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error occurred while checking user: $e');
      return false;
    }
  }
}

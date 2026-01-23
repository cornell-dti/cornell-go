/* This file is the login page for the app. It is called splash because of an old design choice that we didn't change
. It allows the user to sign in with their Cornell email through google sign in, Apple sign in (iOS only), or unrestricted Google sign in (Android only). 
When the user tries to log in, we verify the user with their information, the important ones being authentication and location. */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:provider/provider.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:game/register_page/register_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/navigation_page/bottom_navbar.dart';

class SplashPageWidget extends StatelessWidget {
  SplashPageWidget({Key? key}) : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Shared button style for all authentication buttons
  ButtonStyle get _authButtonStyle => ButtonStyle(
        backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
        fixedSize: MaterialStatePropertyAll<Size>(Size(250, 50)),
        shape: MaterialStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );

  // Shared text style for button labels
  TextStyle get _authButtonTextStyle => TextStyle(
        color: Color.fromARGB(255, 93, 100, 112),
        fontSize: 20,
        fontWeight: FontWeight.w500,
      );

  // Builds Cornell login button with Google Sign-In
  Widget _buildCornellLoginButton(ApiClient client) {
    return Consumer<ApiClient>(
      builder: (context, apiClient, child) {
        return TextButton(
          style: _authButtonStyle,
          onPressed: () async {
            final GoogleSignInAccount? account = await apiClient.signinGoogle();

            if (account == null) {
              displayToast(
                "An error occured while signing you into Google!",
                Status.error,
              );
              return;
            }

            if (!account.email.contains("@cornell.edu")) {
              await apiClient.disconnect();
              displayToast(
                "Only Cornell-affiliated users may use Google Sign-in!",
                Status.error,
              );
              return;
            }

            final auth = await account.authentication;
            final idToken = auth.idToken;

            bool userExists = await apiClient.checkUserExists(
              AuthProviderType.google,
              idToken ?? "",
            );
            if (userExists) {
              // User exists, proceed with the login process
              final gRelogResult = await client.connectGoogleNoRegister(
                account,
              );

              if (gRelogResult != null) {
                return;
              }
            } else {
              // User does not exist, navigate to registration page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RegisterPageWidget(
                    googleUser: account,
                    idToken: idToken,
                  ),
                ),
              );
            }
          },
          child: Text("Cornell Login", style: _authButtonTextStyle),
        );
      },
    );
  }

  // Builds Apple Sign-In button for iOS users
  Widget _buildAppleSignInButton(ApiClient client) {
    return Consumer<ApiClient>(
      builder: (context, apiClient, child) {
        return TextButton(
          style: _authButtonStyle,
          onPressed: () async {
            try {
              // Initiate Apple Sign-In flow
              final credential = await apiClient.signinApple();

              if (credential == null) {
                displayToast(
                  "An error occurred while signing you into Apple!",
                  Status.error,
                );
                return;
              }

              // Check if Apple user exists (similar to Google Sign-In flow)
              final idToken = credential.identityToken;
              bool userExists = await apiClient.checkUserExists(
                AuthProviderType.apple,
                idToken ?? "",
              );

              if (userExists) {
                // User exists, proceed with the login process
                final appleRelogResult = await client.connectAppleNoRegister(
                  credential,
                );

                if (appleRelogResult != null) {
                  return;
                }
              } else {
                // User does not exist, navigate to registration page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RegisterPageWidget(
                      appleUser: credential,
                      idToken: idToken,
                    ),
                  ),
                );
              }
            } catch (e) {
              displayToast(
                "An error occurred during Apple Sign-in!",
                Status.error,
              );
            }
          },
          child: Text("Apple Login", style: _authButtonTextStyle),
        );
      },
    );
  }

  // Builds guest login button for Android users
  // Maintains the original guest access functionality for non-iOS platforms
  Widget _buildGuestButton(ApiClient client) {
    return TextButton(
      style: _authButtonStyle,
      onPressed: () async {
        // Connect as device guest user (original functionality)
        final connectionResult = await client.connectDevice(
          "",
          LoginEnrollmentTypeDto.GUEST,
          "",
          "",
          "",
          [],
        );

        if (connectionResult == null) {
          displayToast("An error occurred while signing you up!", Status.error);
        }
      },
      child: Text("Continue as Guest", style: _authButtonTextStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<ApiClient>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -5,
            top: -5,
            child: SvgPicture.asset(
              'assets/images/splash.svg',
              width: MediaQuery.of(context).size.width + 10,
              height: MediaQuery.of(context).size.height + 10,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              StreamBuilder(
                // CENTRALIZED NAVIGATION: Handles all auth flows (login, registration, reconnect)
                stream: client.clientApi.connectedStream,
                builder: (context, snapshot) {
                  if (client.serverApi != null) {
                    print("ServerApi != null");
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // Navigate to main app from splash page
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => BottomNavBar()),
                        (route) => false,
                      );
                      displayToast("Signed in!", Status.success);
                    });
                  }
                  return Container();
                },
              ),
              _buildCornellLoginButton(client),
              SizedBox(height: 16),
              Row(
                children: <Widget>[
                  SizedBox(width: 69),
                  Expanded(child: Divider(color: Colors.white)),
                  SizedBox(width: 8),
                  LatoText("OR", 14.0, Colors.white, FontWeight.w600),
                  SizedBox(width: 8),
                  Expanded(child: Divider(color: Colors.white)),
                  SizedBox(width: 69),
                ],
              ),
              SizedBox(height: 16),
              // Platform-specific authentication: Apple Sign-In for iOS, Guest access for Android
              Platform.isIOS
                  ? _buildAppleSignInButton(client)
                  : _buildGuestButton(client),
              SizedBox(height: 80),
            ],
          ),
        ],
      ),
    );
  }
}

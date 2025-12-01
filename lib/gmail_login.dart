// gmail_login.dart

import 'dart:async';
import 'dart:convert' show json;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

// IMPORTANT: Replace these with your actual IDs.
// If you are using a server-side backend to verify ID tokens, you need serverClientId.
// For pure client-side verification, you only need to ensure the OAuth setup
// is correct for your platform (iOS/Android/Web).
const String? clientId = null;
const String? serverClientId = null;

/// The scopes required by this application.
/// 'https://www.googleapis.com/auth/contacts.readonly' is used in the example
/// to demonstrate access to a Google API. Change this based on your app's needs.
const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/contacts.readonly',
];

/// A reusable widget to handle Google Sign-In and UI logic.
class GoogleSignInWidget extends StatefulWidget {
  const GoogleSignInWidget({super.key});

  @override
  State<GoogleSignInWidget> createState() => _GoogleSignInWidgetState();
}

class _GoogleSignInWidgetState extends State<GoogleSignInWidget> {
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false; // Has granted necessary API scopes?
  String _contactText = '';
  String _errorMessage = '';
  String _serverAuthCode = '';

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  /// Initializes the Google Sign-In client and starts listening for events.
  void _initializeGoogleSignIn() {
    final GoogleSignIn signIn = GoogleSignIn.instance;
    unawaited(
      signIn.initialize(clientId: clientId, serverClientId: serverClientId).then(
            (_) {
          signIn.authenticationEvents
              .listen(_handleAuthenticationEvent)
              .onError(_handleAuthenticationError);

          // Tries to sign in silently without showing UI.
          signIn.attemptLightweightAuthentication();
        },
      ),
    );
  }

  /// Handles sign-in/sign-out events from the GoogleSignIn stream.
  Future<void> _handleAuthenticationEvent(
      GoogleSignInAuthenticationEvent event) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    // Check for existing authorization for the required scopes.
    final GoogleSignInClientAuthorization? authorization = await user
        ?.authorizationClient
        .authorizationForScopes(scopes);

    setState(() {
      _currentUser = user;
      _isAuthorized = authorization != null;
      _errorMessage = '';
      if (user == null) {
        // Clear contact and server code on sign out
        _contactText = '';
        _serverAuthCode = '';
      }
    });

    // If signed in and authorized, fetch contact data (example API call).
    if (user != null && authorization != null) {
      unawaited(_handleGetContact(user));
    }
  }

  /// Handles errors during the authentication process.
  Future<void> _handleAuthenticationError(Object e) async {
    setState(() {
      _currentUser = null;
      _isAuthorized = false;
      _errorMessage = e is GoogleSignInException
          ? _errorMessageFromSignInException(e)
          : 'Unknown error: $e';
    });
  }

  /// Example: Calls the People API REST endpoint to retrieve contact information.
  Future<void> _handleGetContact(GoogleSignInAccount user) async {
    setState(() {
      _contactText = 'Loading contact info...';
    });

    final Map<String, String>? headers =
    await user.authorizationClient.authorizationHeaders(scopes);
    if (headers == null) {
      setState(() {
        _contactText = '';
        _errorMessage = 'Failed to construct authorization headers.';
      });
      return;
    }

    // This API call requires the 'https://www.googleapis.com/auth/contacts.readonly' scope.
    final http.Response response = await http.get(
      Uri.parse(
        'https://people.googleapis.com/v1/people/me/connections?requestMask.includeField=person.names',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final String status = response.statusCode.toString();
      setState(() {
        _contactText = 'People API error: Status $status';
        _errorMessage = (response.statusCode == 401 || response.statusCode == 403)
            ? 'API access denied. Please re-authorize.'
            : 'People API error: Status $status. Check logs.';
      });
      return;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final String? namedContact = _pickFirstNamedContact(data);
    setState(() {
      if (namedContact != null) {
        _contactText = 'I see you know $namedContact!';
      } else {
        _contactText = 'No contacts to display.';
      }
    });
  }

  /// Utility to parse the first named contact from the People API response.
  String? _pickFirstNamedContact(Map<String, dynamic> data) {
    final connections = data['connections'] as List<dynamic>?;
    final contact = connections?.firstWhere(
          (dynamic contact) => (contact as Map<Object?, dynamic>)['names'] != null,
      orElse: () => null,
    ) as Map<String, dynamic>?;

    if (contact != null) {
      final names = contact['names'] as List<dynamic>;
      final name = names.firstWhere(
            (dynamic name) => (name as Map<Object?, dynamic>)['displayName'] != null,
        orElse: () => null,
      ) as Map<String, dynamic>?;

      if (name != null) {
        return name['displayName'] as String?;
      }
    }
    return null;
  }

  /// Prompts the user to authorize the required scopes.
  Future<void> _handleAuthorizeScopes(GoogleSignInAccount user) async {
    try {
      await user.authorizationClient.authorizeScopes(scopes);
      setState(() {
        _isAuthorized = true;
        _errorMessage = '';
      });
      // Immediately try to get contact data after authorization
      unawaited(_handleGetContact(_currentUser!));
    } on GoogleSignInException catch (e) {
      _errorMessage = _errorMessageFromSignInException(e);
    }
  }

  /// Requests a server auth code (used to exchange for tokens on your backend).
  Future<void> _handleGetAuthCode(GoogleSignInAccount user) async {
    try {
      final GoogleSignInServerAuthorization? serverAuth =
      await user.authorizationClient.authorizeServer(scopes);

      setState(() {
        _serverAuthCode = serverAuth == null ? '' : serverAuth.serverAuthCode;
        _errorMessage = ''; // Clear error on success
      });
    } on GoogleSignInException catch (e) {
      _errorMessage = _errorMessageFromSignInException(e);
    }
  }

  /// Signs out the user and clears session state.
  Future<void> _handleSignOut() async {
    // We use disconnect() to ensure all stored tokens and authorizations are reset.
    await GoogleSignIn.instance.disconnect();
    // The authenticationEvents stream will trigger SignOut, which updates the UI.
  }

  /// Utility to get a user-friendly error message from a GoogleSignInException.
  String _errorMessageFromSignInException(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in canceled by user.',
      _ => 'Google Sign In Error: ${e.code.name.replaceAll('_', ' ')}',
    };
  }

  // --- UI Building Methods ---

  /// Builds the UI for an authenticated user.
  List<Widget> _buildAuthenticatedWidgets(GoogleSignInAccount user) {
    return <Widget>[
      ListTile(
        leading: GoogleUserCircleAvatar(identity: user),
        title: Text(user.displayName ?? ''),
        subtitle: Text(user.email),
      ),
      const Text('Signed in successfully!'),
      const SizedBox(height: 16),
      if (_isAuthorized) ...<Widget>[
        // Authorized: Display API data and other authorized options
        if (_contactText.isNotEmpty) Text(_contactText),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('REFRESH CONTACTS'),
          onPressed: () => _handleGetContact(user),
        ),
        const SizedBox(height: 8),
        if (_serverAuthCode.isEmpty)
          ElevatedButton.icon(
            icon: const Icon(Icons.security),
            label: const Text('REQUEST SERVER CODE'),
            onPressed: () => _handleGetAuthCode(user),
          )
        else
          Column(
            children: [
              const Text('Server auth code:'),
              // Use SelectableText to allow copying the code
              SelectableText(_serverAuthCode, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('CLEAR SERVER CODE'),
                onPressed: () => setState(() => _serverAuthCode = ''),
              ),
            ],
          ),
      ] else ...<Widget>[
        // Authenticated but NOT Authorized for scopes
        const Text(
          'Authorization for required scopes is needed to access API features.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.orange),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.gpp_good),
          onPressed: () => _handleAuthorizeScopes(user),
          label: const Text('REQUEST PERMISSIONS'),
        ),
      ],
      const SizedBox(height: 20),
      ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        onPressed: _handleSignOut,
        label: const Text('SIGN OUT'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      ),
    ];
  }

  /// Builds the UI for an unauthenticated user.
  List<Widget> _buildUnauthenticatedWidgets() {
    return <Widget>[
      const Text(
        'You are not currently signed in.',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 20),
      if (GoogleSignIn.instance.supportsAuthenticate())
        ElevatedButton.icon(
          icon: const Icon(Icons.login),
          onPressed: () async {
            try {
              // Standard sign-in flow
              await GoogleSignIn.instance.authenticate();
            } catch (e) {
              // Error handling is managed by _handleAuthenticationError via the stream
              // but we catch exceptions here just in case of immediate issues.
              if (e is! GoogleSignInException) {
                setState(() => _errorMessage = e.toString());
              }
            }
          },
          label: const Text('SIGN IN WITH GOOGLE'),
        )
      else if (kIsWeb)
      // Web platforms sometimes require a different button render approach
        const Text(
          'Web Sign-In may require specific platform-dependent implementation.',
          style: TextStyle(fontStyle: FontStyle.italic),
        )
      else
        const Text(
          'This platform does not have a known Google Sign-In method.',
          textAlign: TextAlign.center,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final GoogleSignInAccount? user = _currentUser;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Display main body based on authentication status
            if (user != null)
              ..._buildAuthenticatedWidgets(user)
            else
              ..._buildUnauthenticatedWidgets(),

            // Always show the error message if present
            if (_errorMessage.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              Text(
                'Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
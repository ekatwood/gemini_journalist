import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// --- Initialization (Mock for Demo) ---
// In a real application, you would initialize Firebase correctly in main()
// and ensure all platform setups are complete.
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const GoogleSignInApp());
// }

// A simplified main function for running this single file in a development environment.
void main() {
  runApp(const GoogleSignInApp());
}

class GoogleSignInApp extends StatelessWidget {
  const GoogleSignInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GoogleSignInScreen(),
    );
  }
}

// --- Google Sign-In Screen ---

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // FIX: Use the singleton instance as required by your environment.
  // Configuration (like scopes) will be passed to the signIn() method instead.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Define the required scopes here
  static const List<String> requiredScopes = <String>['email'];

  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Listen for changes in the Firebase Authentication state
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  // Core function to handle Google Sign-In and Firebase Authentication
  Future<void> _signInWithGoogle() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 1. Initiate the Google Sign-In flow, passing the scopes here.
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate(
        scopeHint: requiredScopes,
      );

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      // 2. Get the authentication details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential using the Google access token and ID token
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      await _auth.signInWithCredential(credential);

      // Successfully signed in. The authStateChanges listener will update the UI.

    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(context, 'Firebase Auth Error: ${e.message}');
    } catch (e) {
      _showErrorSnackbar(context, 'An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to sign out the user
  Future<void> _signOut() async {
    // Note: signOut() works even if scopes weren't passed during instance creation
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Simple helper function to show a snackbar error message
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }


  // --- UI Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Demo'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Display signed-in or signed-out status
              Text(
                _currentUser != null
                    ? 'Signed In as: ${_currentUser!.displayName ?? _currentUser!.email}'
                    : 'Currently Signed Out',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Sign In / Sign Out Button
              _currentUser == null
                  ? _buildSignInButton()
                  : _buildSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for the Log In button
  Widget _buildSignInButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _signInWithGoogle,
      icon: _isLoading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
      )
          : Image.asset(
        'assets/google_logo.png', // Placeholder: Use a real Google logo asset
        height: 24.0,
      ),
      label: Text(
        _isLoading ? 'Signing In...' : 'Log In with Google',
        style: const TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 3,
      ),
    );
  }

  // Widget for the Sign Out button
  Widget _buildSignOutButton() {
    return ElevatedButton(
      onPressed: _signOut,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        'Sign Out',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
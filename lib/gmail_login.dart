// gmail_login.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_functions.dart';

// --- Google Sign-In Screen ---

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Use the singleton instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Add FirestoreFunctions instance
  final FirestoreFunctions _firestoreFunctions = FirestoreFunctions();

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
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      // Create/Update user profile in Firestore after successful sign-in
      if (user != null) {
        await _firestoreFunctions.createUserProfile(user);
      }

      // Successfully signed in. Dismiss the screen.
      if (mounted) {
        // The screen was pushed, so pop it to return to the LoginPage
        Navigator.of(context).pop();
      }

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
      // appBar: AppBar(
      //   title: const Text('Google Sign-In'),
      //   backgroundColor: Colors.blueAccent,
      //   foregroundColor: Colors.white,
      // ),
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
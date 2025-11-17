// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show document;

// Firebase Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_functions.dart'; // To create user profiles

class AuthProvider extends ChangeNotifier {
  // State variables for the Gemini Journalist app
  String _selectedCountryCode = 'US'; // Default country
  String _selectedLanguageCode = 'en'; // Default language

  // NEW/RENAMED: Time the current page data (translated or raw 'en') was last cached (24h)
  DateTime? _lastCacheTime;

  // Firebase Auth variables
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  User? _currentUser;
  bool _isLoggedIn = false; // Derived from _currentUser != null

  // Theme variables
  ThemeMode _themeMode = ThemeMode.system;

  // Wallet variables (kept from original for completeness, though unused in auth)
  String _walletAddress = '';
  String _walletProvider = '';

  // Getters
  String get selectedCountryCode => _selectedCountryCode;
  String get selectedLanguageCode => _selectedLanguageCode;
  ThemeMode get themeMode => _themeMode;

  // NEW/RENAMED Getter:
  DateTime? get lastCacheTime => _lastCacheTime;

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;

  // Dependency on FirestoreFunctions (injected via Provider)
  FirestoreFunctions? _firestoreFunctions;

  // Used by main.dart to set the dependency
  void setFirestoreFunctions(FirestoreFunctions fs) {
    _firestoreFunctions = fs;
  }

  // --- Cookie Helper Methods (Unchanged) ---
  String? _getCookie(String name) {
    if (!kIsWeb) return null;
    final cookies = html.document.cookie?.split(';');
    if (cookies == null) return null;

    for (var cookie in cookies) {
      final parts = cookie.trim().split('=');
      if (parts[0] == name) {
        return Uri.decodeComponent(parts[1]);
      }
    }
    return null;
  }

  void _setCookie(String name, String value, {Duration? maxAge}) {
    if (!kIsWeb) return;

    // Ensure cookie value is properly encoded
    final encodedValue = Uri.encodeComponent(value);
    String cookie = '$name=$encodedValue';

    if (maxAge != null) {
      final expires = DateTime.now().add(maxAge);
      cookie += '; expires=${expires.toUtc().toIso8601String()}';
    }

    cookie += '; path=/; samesite=Lax';
    html.document.cookie = cookie;
  }

  void _deleteCookie(String name) {
    if (!kIsWeb) return;
    // Set expiration to a past date
    html.document.cookie = '$name=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/';
  }

  // --- Theme Preference Management (Unchanged) ---

  void _loadThemePreference() {
    final String? preference = _getCookie('themePreference');
    if (preference == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (preference == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
  }

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _setCookie('themePreference', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  // --- Country Preference Management (Updated to clear single cache) ---

  void _loadCountryPreference() {
    final String? preference = _getCookie('countryPreference');
    if (preference != null) {
      _selectedCountryCode = preference;
    }
  }

  void setCountryPreference(String countryCode) {
    if (_selectedCountryCode != countryCode) {
      _selectedCountryCode = countryCode;
      _setCookie('countryPreference', countryCode);

      // Clear the single 24h cache when country changes
      _deleteCookie('translatedNewsFetchTime');
      _lastCacheTime = null;
      _deleteCookie('cachedTranslatedNews');

      notifyListeners();
    }
  }

  // --- Language Preference Management (Updated to clear single cache) ---

  void _loadLanguagePreference() {
    final String? preference = _getCookie('languagePreference');
    if (preference != null) {
      _selectedLanguageCode = preference;
    }
  }

  void setLanguagePreference(String languageCode) {
    if (_selectedLanguageCode != languageCode) {
      _selectedLanguageCode = languageCode;
      _setCookie('languagePreference', languageCode);

      // Clear the single 24h cache when language changes
      _deleteCookie('translatedNewsFetchTime');
      _lastCacheTime = null;
      _deleteCookie('cachedTranslatedNews');

      notifyListeners();
    }
  }

  // --- Single Cache Management for Final Web Page Data (24h) ---

  // Caching: Load the time the data was last fetched (24h)
  void _loadLastCacheTime() {
    // Uses 'translatedNewsFetchTime' cookie name
    final String? timeString = _getCookie('translatedNewsFetchTime');
    if (timeString != null) {
      _lastCacheTime = DateTime.tryParse(timeString);
    } else {
      _lastCacheTime = null;
    }
  }

  // Caching: Set the last fetch/translation time
  void setLastCacheTime(DateTime time) {
    _lastCacheTime = time;
    // Set a long-lived cookie for the timestamp itself
    _setCookie('translatedNewsFetchTime', time.toIso8601String());
    notifyListeners();
  }

  // Caching: Get the cached translated news data (24h)
  String? getCachedTranslatedData() {
    // Uses 'cachedTranslatedNews' cookie name
    return _getCookie('cachedTranslatedNews');
  }

  // Caching: Set the cached translated news data (24h timeout)
  void setCachedTranslatedData(String data) {
    // Uses 24-hour expiration for the single content cache
    _setCookie('cachedTranslatedNews', data, maxAge: const Duration(hours: 24));
  }


  // --- Constructor ---
  AuthProvider() {
    _loadThemePreference();
    _loadCountryPreference();
    _loadLanguagePreference();
    _loadLastCacheTime(); // Load the single 24h cache time
    _loadCurrentUser(); // Load Firebase user on startup
  }

  // --- Firebase Auth Methods (Unchanged) ---

  Future<void> _loadCurrentUser() async {
    _currentUser = _auth.currentUser;
    _isLoggedIn = _currentUser != null;
    // If user is logged in, create/update profile
    if (_isLoggedIn && _firestoreFunctions != null) {
      await _firestoreFunctions!.createUserProfile(_currentUser!);
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      // 1. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _currentUser = userCredential.user;
      _isLoggedIn = _currentUser != null;

      // 5. Create/Update user profile in Firestore
      if (_isLoggedIn && _firestoreFunctions != null) {
        await _firestoreFunctions!.createUserProfile(_currentUser!);
      }

      notifyListeners();
    } catch (e) {
      // Handle error, e.g., network issues, configuration errors
      print('Google Sign-In Failed: $e');
      rethrow; // Re-throw the exception so the LoginPage can handle it
    }
  }

  // NOTE: You should also re-add the signOut method for completeness
  Future<void> signOut() async {
    // 1. Sign out from Google
    await _googleSignIn.signOut();
    // 2. Sign out from Firebase
    await _auth.signOut();
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

}
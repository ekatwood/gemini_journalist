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
  DateTime? _lastFetchTime; // Time the news data was last fetched

  // Firebase Auth variables
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
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
  DateTime? get lastFetchTime => _lastFetchTime;
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;

  // Dependency on FirestoreFunctions (injected via Provider)
  FirestoreFunctions? _firestoreFunctions;

  // Used by main.dart to set the dependency after the provider is created
  void setFirestoreFunctions(FirestoreFunctions fs) {
    if (_firestoreFunctions == null) {
      _firestoreFunctions = fs;
      // Initialize the auth listener only after dependencies are set
      _initializeAuthListener();
    }
  }

  AuthProvider() {
    _loadThemePreference();
    _loadCountryPreference();
    _loadLanguagePreference();
    _loadLastFetchTime();
    // NOTE: Auth Listener setup moved to setFirestoreFunctions to ensure dependency order
  }

  void _initializeAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      _currentUser = user;
      _isLoggedIn = user != null;

      if (_isLoggedIn) {
        // Create or update user profile in Firestore
        if (_firestoreFunctions != null) {
          await _firestoreFunctions!.createUserProfile(_currentUser!);
        }
      }

      notifyListeners();
    });
  }

  // --- Auth Methods ---

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user cancelled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign into Firebase
      await _auth.signInWithCredential(credential);
      // The authStateChanges listener will handle state update and Firestore profile creation.

    } on FirebaseAuthException catch (e) {
      print('Google Sign-In Failed: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unknown error occurred during Google Sign-In: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // The authStateChanges listener handles state update and Firestore profile.
    } on FirebaseAuthException catch (e) {
      print('Email Sign-In Failed: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unknown error occurred during Email Sign-In: $e');
      rethrow;
    }
  }

  Future<void> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Create user in Firebase Auth
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // The authStateChanges listener handles state update and Firestore profile.
    } on FirebaseAuthException catch (e) {
      print('Email Registration Failed: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unknown error occurred during Registration: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut(); // Ensure Google state is also cleared
      // The authStateChanges listener handles state update.
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      print('Sign Out Failed: $e');
      rethrow;
    }
  }

  // --- Utility: HTTP Date Format ---
  String _formatHttpDate(DateTime dateTime) {
    const List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final DateTime utcTime = dateTime.toUtc();
    final String weekday = weekdays[utcTime.weekday - 1];
    final String day = utcTime.day.toString().padLeft(2, '0');
    final String month = months[utcTime.month - 1];
    final String year = utcTime.year.toString();
    final String hour = utcTime.hour.toString().padLeft(2, '0');
    final String minute = utcTime.minute.toString().padLeft(2, '0');
    final String second = utcTime.second.toString().padLeft(2, '0');

    return '$weekday, $day $month $year $hour:$minute:$second GMT';
  }

  // --- Cookie Management Functions (Web Only) ---
  String? _getCookie(String key) {
    if (kIsWeb) {
      final String? cookies = html.document.cookie;
      if (cookies != null && cookies.isNotEmpty) {
        final List<String> cookieList = cookies.split(';');
        for (String cookie in cookieList) {
          final List<String> parts = cookie.trim().split('=');
          if (parts.length == 2 && parts[0] == key) {
            return parts[1];
          }
        }
      }
    }
    return null;
  }

  void _setCookie(String key, String value, {Duration? maxAge}) {
    if (kIsWeb) {
      // Default to 365 days for persistent preferences
      final Duration expirationDuration = maxAge ?? const Duration(days: 365);
      final DateTime expirationDate = DateTime.now().add(expirationDuration);

      // Ensure the cookie key does not contain '=' or ';'
      String safeKey = key.replaceAll(RegExp(r'[=;]'), '');

      // Use encodeUriComponent for value to handle spaces/special chars
      String encodedValue = Uri.encodeComponent(value);

      html.document.cookie = '$safeKey=$encodedValue; expires=${_formatHttpDate(expirationDate)}; path=/';
    }
  }

  // Utility to clear a cookie
  void _deleteCookie(String key) {
    if (kIsWeb) {
      final DateTime pastDate = DateTime.now().subtract(const Duration(days: 1));
      String safeKey = key.replaceAll(RegExp(r'[=;]'), '');
      html.document.cookie = '$safeKey=; expires=${_formatHttpDate(pastDate)}; path=/';
    }
  }

  // --- Preference Loaders ---
  void _loadThemePreference() {
    final String? themeValue = _getCookie('themePreference');
    if (themeValue == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeValue == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    // notifyListeners(); // Called once at the end of AuthProvider()
  }

  void _loadCountryPreference() {
    final String? countryCode = _getCookie('countryPreference');
    if (countryCode != null) {
      _selectedCountryCode = countryCode;
    } else {
      _selectedCountryCode = 'US'; // Default
    }
  }

  void _loadLanguagePreference() {
    final String? languageCode = _getCookie('languagePreference');
    if (languageCode != null) {
      _selectedLanguageCode = languageCode;
    } else {
      _selectedLanguageCode = 'en'; // Default
    }
  }

  // Caching: Load the time the news data was last fetched
  void _loadLastFetchTime() {
    final String? timeString = _getCookie('newsFetchTime');
    if (timeString != null) {
      _lastFetchTime = DateTime.tryParse(timeString);
    } else {
      _lastFetchTime = null;
    }
  }

  // Caching: Set the last fetch time
  void setLastFetchTime(DateTime time) {
    _lastFetchTime = time;
    // Set a long-lived cookie for the timestamp itself
    _setCookie('newsFetchTime', time.toIso8601String());
    notifyListeners();
  }

  // --- Public Preference Setters/Togglers ---
  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _setCookie('themePreference', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void setCountryPreference(String countryCode) {
    if (_selectedCountryCode != countryCode) {
      _selectedCountryCode = countryCode;
      _setCookie('countryPreference', countryCode);
      // Changing country requires a refresh, so clear the cache time and data.
      _deleteCookie('newsFetchTime');
      _lastFetchTime = null;
      _deleteCookie('cachedNews');
      notifyListeners();
    }
  }

  void setLanguagePreference(String languageCode) {
    if (_selectedLanguageCode != languageCode) {
      _selectedLanguageCode = languageCode;
      _setCookie('languagePreference', languageCode);
      // Changing language requires a refresh, so clear the cache time and data.
      _deleteCookie('newsFetchTime');
      _lastFetchTime = null;
      _deleteCookie('cachedNews');
      notifyListeners();
    }
  }

  // --- Cache Management for News Data ---

  // NOTE: This cookie will be large, make sure the browser supports it.
  void setCachedNewsData(String data) {
    // 1-hour expiration for the news content cache
    _setCookie('cachedNews', data, maxAge: const Duration(hours: 1));
  }

  String? getCachedNewsData() {
    return _getCookie('cachedNews');
  }
}
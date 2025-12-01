// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show document;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For kIsWeb and kDebugMode

// Firebase Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_functions.dart'; // To create user profiles

// Define 365 days expiration for long-lived preferences
const _kLongCookieDuration = Duration(days: 365);
// Define 1 week expiration for long-lived preferences
const _kWeeklyCookieDuration = Duration(days: 7);
// Define 1 day expiration for the translated text cache
const _kDailyCookieDuration = Duration(hours: 24);

class AuthProvider extends ChangeNotifier {
  // --- State variables for the Gemini Journalist app ---
  String _selectedCountryCode = 'US'; // Default country
  String _selectedLanguageCode = 'en'; // Default language

  // Firebase Auth variables
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  User? _currentUser;
  bool _isLoggedIn = false; // Derived from _currentUser != null

  // Theme variables
  ThemeMode _themeMode = ThemeMode.system;

  // --- Getters ---
  String get selectedCountryCode => _selectedCountryCode;
  String get selectedLanguageCode => _selectedLanguageCode;
  ThemeMode get themeMode => _themeMode;

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;

  // NEW Getter for current translated text (1-day cache)
  String? get getCachedTranslatedData => _getCookie('currentTranslatedText');

  // Dependency: Now using a local instance of FirestoreFunctions
  final FirestoreFunctions _firestoreFunctions = FirestoreFunctions();


  // --- Geolocation Helper (Unchanged) ---
  Future<String> _fetchCountryCodeFromIP() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String countryCode = data['countryCode'] ?? 'US';

        if (kDebugMode) {
          print('Auto-detected Country: $countryCode');
        }
        return countryCode;
      }
    } catch (e) {
      if (kDebugMode) {
        print('IP geolocation failed: $e');
      }
    }
    return 'US';
  }


  // --- Cookie Helper Methods (Refactored) ---
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

  // --- Country Preference Management (365 days cookie) ---

  void _loadCountryPreference() {
    final String? preference = _getCookie('selectedCountry');
    if (preference != null) {
      _selectedCountryCode = preference;
    }
  }

  void setCountryPreference(String countryCode) {
    if (_selectedCountryCode != countryCode) {
      _selectedCountryCode = countryCode;
      // Set the cookie with 365-day expiration
      _setCookie('selectedCountry', countryCode, maxAge: _kLongCookieDuration);
      notifyListeners();
    }
  }

  // --- Language Preference Management (365 days cookie) ---

  void _loadLanguagePreference() {
    final String? preference = _getCookie('selectedLanguage');
    if (preference != null) {
      _selectedLanguageCode = preference;
    }
  }

  void setLanguagePreference(String languageCode) {
    if (_selectedLanguageCode != languageCode) {
      _selectedLanguageCode = languageCode;
      // Set the cookie with 365-day expiration
      _setCookie('selectedLanguage', languageCode, maxAge: _kLongCookieDuration);
      notifyListeners();
    }
  }

  // --- Preferred Languages Management (1 week cookie) ---

  void setPreferredLanguage(String languageCode) {
    if (!kIsWeb) return;

    String? current = _getCookie('preferredLanguages');
    Set<String> languages = {};

    // 1. Load existing languages
    if (current != null && current.isNotEmpty) {
      languages.addAll(current.split(';'));
    }

    // 2. Add the new language if it's not already there
    if (languages.add(languageCode)) {
      final updatedList = languages.join(';');
      // Set the cookie with 365-day expiration
      _setCookie('preferredLanguages', updatedList, maxAge: _kWeeklyCookieDuration);
      print('Updated preferred languages cookie: $updatedList');
    }
  }

  List<String> get preferredLanguageCodes {
    final String? preference = _getCookie('preferredLanguages');
    if (preference != null && preference.isNotEmpty) {
      // The cookie stores codes separated by a semicolon (;)
      return preference.split(';').toList();
    }
    return [];
  }


  // --- Current Translated Text Management (1-day cookie) ---

  void setCachedTranslatedData(String translatedData) {
    if (!kIsWeb) return;
    // Set the cookie with 1-day expiration
    _setCookie('currentTranslatedText', translatedData, maxAge: _kDailyCookieDuration);
    notifyListeners();
  }
  // --- Last Cache Time Management ---

  // Getter for the last cache time
  DateTime? get lastCacheTime {
    final String? timeString = _getCookie('lastCacheTime');
    if (timeString != null) {
      try {
        return DateTime.parse(timeString);
      } catch (e) {
        print('Error parsing cached date: $e');
        return null;
      }
    }
    return null;
  }

  void setLastCacheTime(DateTime time) {
    if (!kIsWeb) return;
    // Set a separate cookie for the time, using the long duration as the cache is cleared by data set
    _setCookie('lastCacheTime', time.toIso8601String(), maxAge: _kDailyCookieDuration);
    notifyListeners(); // Notify listeners of the time change (optional, but good practice)
  }

  // --- Constructor ---
  AuthProvider() {
    _loadThemePreference();
    _loadCountryPreference();
    _loadLanguagePreference();
    _loadCurrentUser(); // Load Firebase user on startup
  }

  // --- Firebase Auth Methods ---

  Future<void> _loadCurrentUser() async {
    _currentUser = _auth.currentUser;
    _isLoggedIn = _currentUser != null;
    // If user is logged in, create/update profile
    if (_isLoggedIn) {
      // Direct use of _firestoreFunctions instance
      await _firestoreFunctions.createUserProfile(_currentUser!);
      // NOTE: Assume createUserProfile handles setting/resetting 'numTranslations' to 0 for the day.
    }
    notifyListeners();
  }

  // NEW: Add signInWithEmailAndPassword for the LoginPage
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = userCredential.user;
      _isLoggedIn = _currentUser != null;

      if (_isLoggedIn) {
        await _firestoreFunctions.createUserProfile(_currentUser!);
      }
      notifyListeners();
    } catch (e) {
      print('Email/Password Sign-In Failed: $e');
      rethrow;
    }
  }

  // NEW: Add registerWithEmailAndPassword for the LoginPage
  Future<void> registerWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = userCredential.user;
      _isLoggedIn = _currentUser != null;

      if (_isLoggedIn) {
        await _firestoreFunctions.createUserProfile(_currentUser!);
      }
      notifyListeners();
    } catch (e) {
      print('Email/Password Registration Failed: $e');
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _currentUser = userCredential.user;
      _isLoggedIn = _currentUser != null;

      // 5. Create/Update user profile in Firestore
      if (_isLoggedIn) {
        await _firestoreFunctions.createUserProfile(_currentUser!);
      }

      notifyListeners();
    } catch (e) {
      print('Google Sign-In Failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
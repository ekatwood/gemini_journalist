// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show document;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For kIsWeb and kDebugMode

// Firebase Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_functions.dart'; // To create user profiles

import 'languages_dropdown.dart' as ld;

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

  // Theme variables
  ThemeMode _themeMode = ThemeMode.system;

  // --- Getters ---
  String get selectedCountryCode => _selectedCountryCode;
  String get selectedLanguageCode => _selectedLanguageCode;
  ThemeMode get themeMode => _themeMode;

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

  // MODIFIED: setCountryPreference
  void setCountryPreference(String countryCode) {
    if (_selectedCountryCode != countryCode) {
      _selectedCountryCode = countryCode;

      // 1. Get the list of language names for the new country
      final List<String>? countryLanguageNames =
      ld.countryLanguages[countryCode];

      // 2. Determine the default language code
      if (countryLanguageNames != null && countryLanguageNames.isNotEmpty) {
        // Get the first language name (e.g., 'French' for 'FR')
        final String defaultLanguageName = countryLanguageNames.first;

        // Convert the name back to its code (e.g., 'fr') using the new map
        final String? defaultLanguageCode =
        ld.languageNameToCodeMap[defaultLanguageName];

        if (defaultLanguageCode != null) {
          // 3. Automatically set the language preference to the default
          setLanguagePreference(defaultLanguageCode);
          return; // Exit early if we set the language
        }
      }

      // Fallback: If no language is found or the lookup fails, default to 'English'
      setLanguagePreference('en');

      notifyListeners();
    }
  }

  void setLanguagePreference(String languageCode) {
    if (_selectedLanguageCode != languageCode) {
      _selectedLanguageCode = languageCode;
      notifyListeners();
    }
  }

  // --- Constructor ---
  AuthProvider() {
    _loadThemePreference();
    _loadCountryPreference();
  }
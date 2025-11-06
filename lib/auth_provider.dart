// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show document;

class AuthProvider extends ChangeNotifier {
  // State variables for the Gemini Journalist app
  String _selectedCountryCode = 'US'; // Default country
  String _selectedLanguageCode = 'en'; // Default language
  DateTime? _lastFetchTime; // Time the news data was last fetched

  // Theme and login variables kept from model for completeness
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoggedIn = false;
  String _walletAddress = '';
  String _walletProvider = '';

  // Getters
  String get selectedCountryCode => _selectedCountryCode;
  String get selectedLanguageCode => _selectedLanguageCode;
  ThemeMode get themeMode => _themeMode;
  DateTime? get lastFetchTime => _lastFetchTime;

  AuthProvider() {
    _loadThemePreference();
    _loadCountryPreference();
    _loadLanguagePreference();
    _loadLastFetchTime();
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
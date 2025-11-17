// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // To open source links
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'dart:convert'; // For JSON encoding/decoding

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_functions.dart';
import 'auth_provider.dart';
import 'login_page.dart'; // NEW: Import the login page

// import 'firebase_options.dart';

void main() async { // ADDED async
  // Ensure we are ready to use Providers/Flutter bindings
  WidgetsFlutterBinding.ensureInitialized(); // ADDED

  // TODO: Initialize Firebase here.
  // Replace YOUR_FIREBASE_OPTIONS with the actual options for your platform.
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Using a stub initialization for now:
  if (kDebugMode) {
    print('*** Firebase Initialized (Stub) ***');
  }
  await GoogleSignIn.instance.initialize(
    params: const GoogleSignInParams(
      scopes: [
        'email',
        'profile', // You usually want profile along with email
      ],
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // AuthProvider handles user preferences and caching logic
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // FirestoreFunctions is stateless, so we can use Provider.value
        Provider<FirestoreFunctions>(create: (_) => FirestoreFunctions()),
      ],
      child: const GeminiJournalist(),
    ),
  );
}

class GeminiJournalist extends StatelessWidget {
  const GeminiJournalist({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firestoreFunctions = Provider.of<FirestoreFunctions>(context, listen: false);

    // CRITICAL: Inject FirestoreFunctions into AuthProvider after creation
    // This allows the AuthProvider to call Firestore methods like createUserProfile
    authProvider.setFirestoreFunctions(firestoreFunctions);


    return MaterialApp(
      title: 'Gemini Correspondent',
      // Use the theme from the AuthProvider
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      themeMode: authProvider.themeMode,
      // CHANGE 1: Always show NewsHomePage, regardless of login status.
      home: const NewsHomePage(),
    );
  }
}

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  List<NewsItem> _newsItems = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is called when dependencies change, including on first build.
    // We use a small Future.microtask to ensure the provider is ready.
    Future.microtask(() => _fetchNews());
  }

  // Stub for the GCF HTTP call (will be replaced with actual http calls upon deployment)
  Future<List<NewsItem>> _callGoogleCloudTranslate(List<NewsItem> items, String targetLanguageCode) async {
    print('Calling GCF for translation to $targetLanguageCode...');

    // 1. Prepare JSON payload
    final String payload = jsonEncode({
      'news_items': items.map((item) => item.toJson()).toList(),
      'target_language': targetLanguageCode,
    });

    // 2. STUB: Simulate the HTTP POST to your GCF endpoint.
    // When deploying, replace this with an actual HTTP POST request (e.g., using the 'http' package).
    await Future.delayed(const Duration(seconds: 2));

    // 3. STUB: Return the original list. In a real scenario, you parse the translated JSON response here.
    print('GCF (Stub) returned items (simulated translation).');
    return items;
  }

  Future<void> _fetchNews() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreFunctions = Provider.of<FirestoreFunctions>(context, listen: false);

    // Get current preferences and the single cache data
    final countryCode = authProvider.selectedCountryCode;
    final languageCode = authProvider.selectedLanguageCode;
    final lastCacheTime = authProvider.lastCacheTime;
    final cachedData = authProvider.getCachedTranslatedData(); // This is the 24h cache

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 1. Check for valid Cache (24-hour timeout)
    if (kIsWeb && cachedData != null && lastCacheTime != null) {
      // 24 hours ago
      final dayAgo = DateTime.now().subtract(const Duration(hours: 24));

      if (lastCacheTime.isAfter(dayAgo)) {
        try {
          final List<dynamic> jsonList = jsonDecode(cachedData);
          // Load data from the single cache
          _newsItems = jsonList.map((json) => NewsItem.fromFirestore(json)).toList();
          setState(() {
            _isLoading = false;
          });
          print('Loaded news from 24h cache. Last fetch: $lastCacheTime');
          return; // Use cache and stop
        } catch (e) {
          print('Error parsing cached data: $e');
          // Fall through to fetch new data
        }
      } else {
        print('Cache expired. Fetching new data.');
      }
    }

    // 2. Fetch Raw Data from Firestore (Always happens if cache is invalid/missing)
    List<NewsItem> rawNewsItems = [];
    try {
      // Fetch raw data using preferences
      rawNewsItems = await firestoreFunctions.fetchNewsItems(countryCode, languageCode);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch raw news: ${e.toString()}';
        _isLoading = false;
      });
      print('Error: $_errorMessage');
      return; // Stop on error
    }

    // 3. Translate and Cache Result
    List<NewsItem> finalNewsItems = rawNewsItems;

    if (languageCode != 'en') { // Assuming 'en' is the source language of the raw data
      try {
        final translatedItems = await _callGoogleCloudTranslate(rawNewsItems, languageCode);
        finalNewsItems = translatedItems;
      } catch (e) {
        print('Translation Error: ${e.toString()}. Displaying raw data instead.');
        // If translation fails, fall through and display the raw (untranslated) items.
        // Do NOT cache in this case, as the data is not what the user requested.
      }
    }

    // 4. Update UI and Cache the Final Result (Translated or Raw 'en' data)
    setState(() {
      _newsItems = finalNewsItems;
      _isLoading = false;
    });

    // Cache the final result (Web only)
    if (kIsWeb && finalNewsItems.isNotEmpty) {
      final now = DateTime.now();
      final jsonString = jsonEncode(finalNewsItems.map((item) => item.toJson()).toList());

      // This overrides the single cookie with new data and sets the 24h timeout
      authProvider.setCachedTranslatedData(jsonString);
      authProvider.setLastCacheTime(now);
      print('Final news data cached at $now (24h override).');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isLoggedIn;

    // Trigger a refetch if preferences changed (as their setters clear cache)
    final currentCountry = authProvider.selectedCountryCode;
    final currentLanguage = authProvider.selectedLanguageCode;

    // Get display name for personalized greeting
    final displayName = isLoggedIn ? (authProvider.currentUser?.displayName ?? authProvider.currentUser?.email ?? 'User') : 'Guest';


    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $displayName!'), // Personalized title
        actions: [
          // Theme Toggle
          IconButton(
            icon: Icon(
              authProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: authProvider.toggleThemeMode,
          ),

          // CHANGE 2: Conditional Login/Logout Button
          if (isLoggedIn)
          // Show Logout button if logged in
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () async {
                await authProvider.signOut();
              },
            )
          else
          // Show Sign In button if not logged in
            TextButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              onPressed: () {
                // Navigate to the Login Page using push (or pushReplacement for a clean stack)
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // --- Control Row: Country, Language ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Country Dropdown
                _buildDropdown(
                  context,
                  'Country',
                  currentCountry,
                  countryList,
                      (String? newValue) {
                    if (newValue != null) {
                      authProvider.setCountryPreference(newValue);
                      _fetchNews(); // Re-fetch data on preference change
                    }
                  },
                ),
                const SizedBox(width: 16),

                // Language Translator Selector
                _buildDropdown(
                  context,
                  'Translate To',
                  currentLanguage,
                  languageList,
                      (String? newValue) {
                    if (newValue != null) {
                      authProvider.setLanguagePreference(newValue);
                      // TODO: just do a _translateText() function
                      _fetchNews(); // Re-fetch data on preference change
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // --- News Display Area ---
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  // Helper method to build the country/language dropdowns
  Widget _buildDropdown(
      BuildContext context,
      String label,
      String currentValue,
      Map<String, String> items,
      void Function(String?) onChanged,
      ) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentValue,
        onChanged: onChanged,
        hint: Text(label),
        items: items.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
      );
    }

    if (_newsItems.isEmpty) {
      return const Center(child: Text('No news items found for this selection.'));
    }

    // Display the list of news items
    return ListView.builder(
      itemCount: _newsItems.length,
      itemBuilder: (context, index) {
        final item = _newsItems[index];
        return NewsItemCard(
          number: index + 1,
          title: item.title,
          summary: item.summary,
          sources: item.sources,
        );
      },
    );
  }
}

// Widget to display a single news item
class NewsItemCard extends StatelessWidget {
  final int number;
  final String title;
  final String summary;
  final List<String> sources;

  const NewsItemCard({
    super.key,
    required this.number,
    required this.title,
    required this.summary,
    required this.sources,
  });

  // Utility to launch the URL in the source. This is a stub, assuming the source
  // contains the full link text/URL as a string.
  Future<void> _launchUrl(String sourceText) async {
    // A more robust implementation would parse the link from the source text
    // For this stub, we'll just check if the text *looks* like a URL and launch it.
    final String urlString = sourceText.split(':').last.trim(); // Heuristic to get URL part
    final Uri uri = Uri.tryParse(urlString) ?? Uri.parse('https://news.google.com'); // Fallback

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      // print('Could not launch $uri');
      // Show an error to the user if a real link fails to open
      if (kDebugMode) {
        print('Could not launch $uri');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title (without the number, as requested)
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Summary Text
            Text(summary),
            const SizedBox(height: 12),

            // Footer with Sources
            const Text(
              'Footer with Sources:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...sources.map((source) => Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: InkWell(
                onTap: () => _launchUrl(source),
                child: Text(
                  source,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // To open source links
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'dart:convert'; // For JSON encoding/decoding

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_functions.dart';
import 'auth_provider.dart';
import 'login_page.dart'; // NEW: Import the login page

// --- Constants for Dropdown Menus (Simplified for stub) ---
const Map<String, String> countryList = {
  'US': 'United States',
  'GB': 'United Kingdom',
  'IN': 'India',
  'JP': 'Japan',
  'DE': 'Germany',
  // Add many more countries here
};

const Map<String, String> languageList = {
  'en': 'English',
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'ja': 'Japanese',
  // Add many more languages here
};

// Replace with your actual Firebase options import if needed
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

  Future<void> _fetchNews() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreFunctions = Provider.of<FirestoreFunctions>(context, listen: false);

    // Guard Clause: No longer check for login status here, as anonymous users can view the stub data.
    // If you implement real security rules, you would add a check here.

    // Get current preferences
    final countryCode = authProvider.selectedCountryCode;
    final languageCode = authProvider.selectedLanguageCode;
    final lastFetchTime = authProvider.lastFetchTime;
    final cachedData = authProvider.getCachedNewsData();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 1. Check for valid cache
    if (kIsWeb && cachedData != null && lastFetchTime != null) {
      final hourAgo = DateTime.now().subtract(const Duration(hours: 1));

      if (lastFetchTime.isAfter(hourAgo)) {
        try {
          // Attempt to parse cached data
          final List<dynamic> jsonList = jsonDecode(cachedData);
          _newsItems = jsonList.map((json) => NewsItem.fromFirestore(json)).toList();
          setState(() {
            _isLoading = false;
          });
          print('Loaded news from cache. Last fetch: $lastFetchTime');
          return; // Use cache and stop
        } catch (e) {
          print('Error parsing cached data: $e');
          // Fall through to fetch new data
        }
      } else {
        print('Cache expired. Fetching new data.');
      }
    }


    // 2. Fetch new data
    try {
      final fetchedItems = await firestoreFunctions.fetchNewsItems(countryCode, languageCode);

      setState(() {
        _newsItems = fetchedItems;
        _isLoading = false;
      });

      // 3. Update cache and timestamp on success (Web only)
      if (kIsWeb && fetchedItems.isNotEmpty) {
        final now = DateTime.now();
        final jsonString = jsonEncode(fetchedItems.map((item) => item.toJson()).toList());
        authProvider.setCachedNewsData(jsonString);
        authProvider.setLastFetchTime(now);
        print('News fetched and cached at $now');
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch news: ${e.toString()}';
        _isLoading = false;
      });
      print('Error: $_errorMessage');
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
// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // To open source links
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'dart:convert'; // For JSON encoding/decoding

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'firestore_functions.dart';
import 'auth_provider.dart' as ap;
import 'country_data.dart'; //
import 'languages_dropdown.dart'; //

void main() async { // ADDED async
  // Ensure we are ready to use Providers/Flutter bindings
  WidgetsFlutterBinding.ensureInitialized(); // ADDED

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Using a stub initialization for now:

  if (kDebugMode) {
    print('*** Firebase Initialized ***');
  }

  runApp(
    MultiProvider(
      providers: [
        // AuthProvider handles user preferences and caching logic
        ChangeNotifierProvider(create: (_) => ap.AuthProvider()),
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
    final authProvider = Provider.of<ap.AuthProvider>(context);
    final firestoreFunctions = Provider.of<FirestoreFunctions>(context, listen: false);

    // Custom Colors for the Newspaper Theme
    // Parchment for Light Mode Background
    const Color parchment = Color(0xFFFAF0E6); // A light, off-white beige
    // Ink for Light Mode Text/Primary
    const Color ink = Color(0xFF1E1E1E); // Very dark gray, almost black
    // Dark Background for Dark Mode
    const Color darkPaper = Color(0xFF121212); // Standard dark mode gray
    // Off-White/Sepia for Dark Mode Text
    const Color sepia = Color(0xFFEFECE9); // A soft, off-white
    // Define the desired TextStyle for the body text
    const TextStyle bodyTextStyle = TextStyle(fontSize: 16.0);

    return MaterialApp(
      title: 'Gemini Correspondent',
      // Use the theme from the AuthProvider
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'LibreBaskerville',
        // Define a custom ColorScheme
        colorScheme: const ColorScheme.light(
          primary: ink, // Main elements (e.g., App Bar/Primary buttons)
          secondary: ink, // Secondary elements
          background: parchment, // **Main background color**
          surface: parchment, // Card/Dialog backgrounds
          onBackground: ink, // **Text color on the background**
          onSurface: ink, // Text color on cards
        ),
        // Ensures the Scaffold background color uses the new background color
        scaffoldBackgroundColor: parchment,
        textTheme: TextTheme(
          bodyMedium: bodyTextStyle.copyWith(color: ink),
        ),
      ),
      // --- DARK MODE THEME ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'LibreBaskerville',
        // Define a custom ColorScheme
        colorScheme: const ColorScheme.dark(
          primary: sepia, // Main elements
          secondary: sepia, // Secondary elements
          background: darkPaper, // **Main background color**
          surface: darkPaper, // Card/Dialog backgrounds
          onBackground: sepia, // **Text color on the background**
          onSurface: sepia, // Text color on cards
        ),
        // Ensures the Scaffold background color uses the new background color
        scaffoldBackgroundColor: darkPaper,
        textTheme: TextTheme(
          bodyMedium: bodyTextStyle.copyWith(color: sepia),
        ),
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
  bool _initialFetchDone = false;

  // NEW: Track the currently selected category
  String _selectedCategory = 'Headlines';

  @override
  void didChangeDependencies() {

    super.didChangeDependencies();
    // Only fetch news on the FIRST time dependencies change (i.e., on initial build)
    if (!_initialFetchDone) {
      Future.microtask(() => _fetchNews());
      _initialFetchDone = true;
    }
  }

  Future<void> _fetchNews() async {
    final authProvider = Provider.of<ap.AuthProvider>(context, listen: false);
    final firestoreFunctions = Provider.of<FirestoreFunctions>(context, listen: false);

    // Get current preferences and the single cache data
    final countryCode = authProvider.selectedCountryCode;
    final languageCode = authProvider.selectedLanguageCode;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 2. Fetch Raw Data from Firestore (Always happens if cache is invalid/missing)
    List<NewsItem> rawNewsItems = [];
    try {
      // Fetch raw data using preferences
      rawNewsItems = await firestoreFunctions.fetchNewsItems(countryCode, languageCode, _selectedCategory);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch raw news: ${e.toString()}';
        _isLoading = false;
      });
      print('Error: $_errorMessage');
      return; // Stop on error
    }

    List<NewsItem> finalNewsItems = rawNewsItems;

    setState(() {
      _newsItems = finalNewsItems;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ap.AuthProvider>(context);

    // Trigger a refetch if preferences changed (as their setters clear cache)
    final currentCountry = authProvider.selectedCountryCode;
    final currentLanguage = authProvider.selectedLanguageCode;

    // *** NEW LOGIC STARTS HERE ***
    // 1. Get the list of language names for the current country
    final countryLangNames = countryLanguages[currentCountry] ?? [];

    // 2. Convert these names into a Set of their language codes for efficient lookup
    final Set<String> countryLanguageCodes = countryLangNames
        .map((name) {
      // Look up the code using the reverse map from languages_dropdown.dart
      // Note: You may need to update the import for _languageNameToCodeMap
      // or create a public helper function in languages_dropdown.dart to access it.
      // For simplicity, we'll assume we can access it directly after updating imports/exports.
      return languageNameToCodeMap[name];
    })
        .whereType<String>() // Filter out nulls if a name isn't found
        .toSet();
    // *** NEW LOGIC ENDS HERE ***

    return Scaffold(
      appBar: AppBar(
        // Centers the logo in the AppBar
        centerTitle: true,

        title: ClipRRect(
          borderRadius: BorderRadius.circular(5.6), // Adjust the radius for more/less rounding
          child: Image.asset(
            'assets/logo.png', // Make sure to match your actual asset path
            height: 54,        // Adjust height to fit your AppBar nicely
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          // Theme Toggle stays floating on the right
          IconButton(
            icon: Icon(
              // Check the actual resolved brightness of the application context
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: authProvider.toggleThemeMode,
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
                  Map<String, String>.fromIterable(
                    allCountries,
                    key: (country) => country.code,
                    value: (country) => country.name,
                  ),
                      (String? newValue) {
                    if (newValue != null) {
                      authProvider.setCountryPreference(newValue);
                      _fetchNews(); // Re-fetch data on preference change
                    }
                  },
                  // Pass an empty set for the country dropdown
                  {},
                ),
                const SizedBox(width: 16),

                // Language Translator Selector
                _buildDropdown(
                  context,
                  'Translate To',
                  currentLanguage,
                  Map<String, String>.fromIterable(
                    allLanguages, // <--- Change this
                    key: (language) => language.code,
                    value: (language) => language.name,
                  ),
                      (String? newValue) {
                    if (newValue != null) {
                      // TODO: translate if it is not already in db
                      authProvider.setLanguagePreference(newValue);
                      _fetchNews(); // Re-fetch data on preference change
                    }
                  },
                  // Pass the calculated set of highlighted codes!
                  countryLanguageCodes,
                ),
              ],
            ),
          ),

          // --- NEW: Category Buttons Section ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                'Headlines',
                'Business and Markets',
                'Politics',
                'Art and Culture',
                'Sports',
                'Science and Technology'
              ].map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    showCheckmark: false,
                    // Force the background to use your primary ink color when selected
                    selectedColor: Theme.of(context).colorScheme.primary,
                    // Update the text color dynamically based on selection state
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.background // Light text when selected
                          : Theme.of(context).colorScheme.onBackground, // Dark text when unselected
                      //fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _fetchNews();
                      }
                    },
                  )
                );
              }).toList(),
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
      // NEW ARGUMENT: A set of codes that should be highlighted/bolded.
      Set<String> highlightCodes,
      ) {

    // 1. Separate the items into two lists, maintaining the original order
    final List<MapEntry<String, String>> highlightedItems = [];
    final List<MapEntry<String, String>> remainingItems = [];

    // Iterate over the items in their original order (from the passed Map)
    items.entries.forEach((entry) {
      if (highlightCodes.contains(entry.key)) {
        highlightedItems.add(entry);
      } else {
        remainingItems.add(entry);
      }
    });

    // 2. Build the final list of DropdownMenuItem widgets
    final List<DropdownMenuItem<String>> menuItems = [];

    // Add Highlighted (Country-Specific) Languages (in original order)
    menuItems.addAll(highlightedItems.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(
          entry.value,
          style: null, //const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }));

    // Add the Divider if there are both highlighted languages AND other languages
    if (highlightedItems.isNotEmpty && remainingItems.isNotEmpty) {
      // A non-selectable DropdownMenuItem containing a Divider
      menuItems.add(
        const DropdownMenuItem<String>(
          value: null, // Set value to null to prevent selection
          enabled: false, // Crucial: Prevents interaction
          child: Divider(
            height: 1, // Minimize space
            thickness: 1,
          ),
        ),
      );
    }

    // Add Remaining Languages (in original order)
    menuItems.addAll(remainingItems.map((entry) {
      // Note: We don't need to check for highlighting again here.
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(
          entry.value,
          style: null, // Normal style
        ),
      );
    }));


    // 3. Return the final DropdownButton
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentValue,
        onChanged: onChanged,
        hint: Text(label),
        // Use the newly constructed list of items
        items: menuItems,
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
  // CHANGE 1: Update type to the new SourceLink model
  final List<SourceLink> sources;

  const NewsItemCard({
    super.key,
    required this.number,
    required this.title,
    required this.summary,
    required this.sources,
  });

  // Utility to launch the URL from the SourceLink object
  Future<void> _launchUrl(String urlString) async {
    // CHANGED: Use the direct URL string
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
              'Sources:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            // CHANGE 2: Iterate over SourceLink objects
            ...sources.map((source) => Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: InkWell(
                // Use source.url for launching
                onTap: () => _launchUrl(source.url),
                child: Text(
                  // Use SourceLink.toString() for display (e.g., 'Title: URL')
                  source.toString(),
                  style: const TextStyle(
                    color: Colors.blue,
                    //decoration: TextDecoration.underline,
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
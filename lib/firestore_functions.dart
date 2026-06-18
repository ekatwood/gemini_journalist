// firestore_functions.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode; // Added for print

// --- NEW: Source Model ---
class SourceLink {
  final String linkTitle;
  final String url;

  SourceLink({required this.linkTitle, required this.url});

  // Factory to create a SourceLink from a map (the format stored in Firestore)
  factory SourceLink.fromMap(Map<String, dynamic> data) {
    return SourceLink(
      linkTitle: data['link_title'] ?? 'No Title',
      url: data['url'] ?? '',
    );
  }

  // To convert the object into a JSON string for cookie storage
  Map<String, dynamic> toJson() => {
    'link_title': linkTitle,
    'url': url,
  };

  // Utility to combine title and URL for the NewsItemCard display
  @override
  String toString() => linkTitle;
}

// Model for a single news item
class NewsItem {
  final String title;
  final String summary;
  // CHANGED: Use the new SourceLink model
  final List<SourceLink> sources;

  NewsItem({
    required this.title,
    required this.summary,
    required this.sources,
  });

  factory NewsItem.fromFirestore(Map<String, dynamic> data) {
    // UPDATED: Map the list of source objects into a List<SourceLink>
    List<dynamic> rawSources = data['sources'] ?? [];
    List<SourceLink> sources = rawSources
        .whereType<Map<String, dynamic>>()
        .map((s) => SourceLink.fromMap(s))
        .toList();

    return NewsItem(
      title: data['title'] ?? 'No Title',
      summary: data['summary'] ?? 'No Summary',
      sources: sources,
    );
  }

  // To convert the object into a JSON string for cookie storage
  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    // UPDATED: Convert SourceLink back to JSON map for caching
    'sources': sources.map((s) => s.toJson()).toList(),
  };
}

// Stubs for your Firestore operations
class FirestoreFunctions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This will be called to get the news items from the database
  // ADDED: category parameter to target the correct nested map
  Future<List<NewsItem>> fetchNewsItems(String countryCode, String languageCode, String category) async {
    print('Fetching news for $countryCode in $languageCode [$category] from Firestore...');

    try {
      // 1. Query the 'news_summaries' collection
      QuerySnapshot snapshot = await _firestore
          .collection('news_summaries')
      // 2. Filter by country and language
          .where('country', isEqualTo: countryCode)
          .where('language', isEqualTo: languageCode)
      // 3. Get the most recent document
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No news found for $countryCode in $languageCode.');
        return [];
      }

      // 4. Extract the data from the single result
      final docData = snapshot.docs.first.data() as Map<String, dynamic>;

      // Get the 'news_data' object
      final Map<String, dynamic> newsDataObject = docData['news_data'] ?? {};

      // UPDATED: Drill down into the specific category map (e.g., 'Headlines', 'Politics')
      final Map<String, dynamic> categoryObject = newsDataObject[category] ?? {};

      // UPDATED: Get the 'news_items' list from inside that category object
      final List<dynamic> newsDataList = categoryObject['news_items'] ?? [];

      // 5. Map the list of JSON objects to NewsItem objects
      final List<NewsItem> newsItems = newsDataList
          .whereType<Map<String, dynamic>>()
          .map((itemData) => NewsItem.fromFirestore(itemData))
          .toList();

      if (kDebugMode) {
        print('Successfully fetched ${newsItems.length} items for category "$category".');
      }
      return newsItems;
    } catch (e) {
      print('Error fetching news from Firestore: $e');
      rethrow;
    }
  }
}
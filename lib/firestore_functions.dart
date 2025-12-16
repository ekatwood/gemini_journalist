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

  Future<void> createUserProfile(User user) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);

    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastSignInTime': FieldValue.serverTimestamp(),
      // Add any other default profile data here
    };

    // Use set with merge: true to create the document if it doesn't exist,
    // or update the sign-in time if it does.
    try {
      await userDocRef.set(userData, SetOptions(merge: true));
      print('User profile created/updated for ${user.email}');
    } catch (e) {
      print('Error creating user profile in Firestore: $e');
      rethrow;
    }
  }

  // This will be called to get the news items from the database
  Future<List<NewsItem>> fetchNewsItems(String countryCode, String languageCode) async {
    print('Fetching news for $countryCode in $languageCode from Firestore...');

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
      // CHANGE 1: Get the 'news_data' object
      final Map<String, dynamic> newsDataObject = docData['news_data'] ?? {};
      // CHANGE 2: Get the 'news_items' list from the news_data object
      final List<dynamic> newsDataList = newsDataObject['news_items'] ?? [];


      // 5. Map the list of JSON objects (from 'news_stories') to NewsItem objects
      final List<NewsItem> newsItems = newsDataList
          .whereType<Map<String, dynamic>>()
      // CHANGE 3: Use the new list to map
          .map((itemData) => NewsItem.fromFirestore(itemData))
          .toList();

      if (kDebugMode) {
        print('Successfully fetched ${newsItems.length} news items from Firestore.');
      }
      return newsItems;
    } catch (e) {
      print('Error fetching news from Firestore: $e');
      rethrow;
    }
  }
}
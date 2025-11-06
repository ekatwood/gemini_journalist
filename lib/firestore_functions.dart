// firestore_functions.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Model for a single news item
class NewsItem {
  final String title;
  final String summary;
  // TODO: make a touple List, (title, url)
  final List<String> sources; // List of source URLs/text

  NewsItem({
    required this.title,
    required this.summary,
    required this.sources,
  });

  factory NewsItem.fromFirestore(Map<String, dynamic> data) {
    // Assuming the source data is a list of strings
    List<dynamic> rawSources = data['sources'] ?? [];
    List<String> sources = rawSources.map((s) => s.toString()).toList();

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
    'sources': sources,
  };
}

// Stubs for your Firestore operations
class FirestoreFunctions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This will be called to get the news items from the database
  // The actual implementation will read from a structure like:
  // /countries/{countryCode}/news/{languageCode}/items/{1...10}
  Future<List<NewsItem>> fetchNewsItems(String countryCode, String languageCode) async {
    // --- STUB IMPLEMENTATION START ---
    print('Fetching news for $countryCode in $languageCode from Firestore...');

    // Simulate network delay and data retrieval
    await Future.delayed(const Duration(seconds: 1));

    // You would query Firestore here:
    // QuerySnapshot snapshot = await _firestore
    //     .collection('countries')
    //     .doc(countryCode)
    //     .collection('news')
    //     .doc(languageCode)
    //     .collection('items')
    //     .orderBy(FieldPath.documentId) // Assuming document IDs are '1', '2', etc.
    //     .limit(10)
    //     .get();

    // return snapshot.docs.map((doc) => NewsItem.fromFirestore(doc.data() as Map<String, dynamic>)).toList();

    // Using the example data for the stub
    final exampleData = [
      {
        'title': 'The Longest-Ever Federal Government Shutdown Continues',
        'summary': 'The U.S. federal government shutdown has entered a record-breaking period, surpassing the length of any previous shutdown. The key issue is a continued stalemate between the White House and Congress over budget negotiations...',
        'sources': ['The Guardian: Record-breaking shutdown', 'The Washington Post: FAA orders 10% cut'],
      },
      // ... Add your other 9 items similarly ...
    ];

    if (countryCode == 'US' && languageCode == 'en') {
      return exampleData.map((data) => NewsItem.fromFirestore(data)).toList();
    } else {
      // Return empty list or a default item for other countries/languages
      return [
        NewsItem(
          title: 'News Not Found',
          summary: 'No data available for $countryCode in $languageCode. Defaulting to an example.',
          sources: ['Example Source 1', 'Example Source 2'],
        )
      ];
    }
    // --- STUB IMPLEMENTATION END ---
  }
}
import 'languages_dropdown.dart';

// Function to call the Cloud Function
// Future<Map<String, dynamic>> translateNews(
//     String selectedLanguage, List<Map<String, dynamic>> newsItems) async {
//
//   // 1. Get the required ISO 639-1 code
//   final targetCode = dropdownCodeMap[selectedLanguage] ?? 'en';
//
//   final url = 'YOUR_CLOUD_FUNCTION_URL';
//
//   // 2. Construct the payload using the mapped code
//   final payload = {
//     'news_items': newsItems,
//     'target_language': targetCode, // This is the required ISO code
//   };
//
//   // ... (rest of your HTTP POST request logic) ...
// }
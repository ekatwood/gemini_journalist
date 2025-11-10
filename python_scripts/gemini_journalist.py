import requests
import json
import time
from datetime import datetime

# --- CONFIGURATION (Replace with your actual settings) ---
# NOTE: In a secure Google Cloud environment (e.g., Cloud Functions, Run),
# you typically don't hardcode an API key. You would use Application Default Credentials (ADC)
# or a service account for both Gemini and Firestore.
#
# For testing locally with the API, you can place your key here:
GEMINI_API_KEY = ""
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent"
FIREBASE_PROJECT_ID = "your-firebase-project-id" # e.g., "my-news-app-12345"

# --- FIREBASE / GOOGLE CLOUD AUTH SETUP ---
# In a real Python Google Cloud environment, you would use the Firebase Admin SDK.
# For demonstration, we'll mock the Firestore client setup.
# You would need to install: pip install firebase-admin
# from firebase_admin import credentials, initialize_app, firestore

# cred = credentials.ApplicationDefault()
# initialize_app(cred, {'projectId': FIREBASE_PROJECT_ID})
# db = firestore.client()

# Placeholder class for Firestore interaction (Replace with actual Firebase Admin SDK code)
class FirestoreClientMock:
    def collection(self, collection_path):
        print(f"--- MOCK: Preparing to access collection: {collection_path} ---")
        return self

    def add(self, data):
        timestamp = datetime.now().isoformat()
        doc_id = f"news-item-{timestamp}"
        print(f"\n--- MOCK: SAVING DOCUMENT to Firestore ---")
        print(f"Collection: news_summaries")
        print(f"Document ID: {doc_id}")
        print(f"Data Payload:\n{json.dumps(data, indent=2)}")
        print("--- END MOCK SAVE ---\n")
        return doc_id

db = FirestoreClientMock()

# --- JSON Response Schema Definition (For Structured Output) ---
# This schema defines the exact structure the model MUST return.
NEWS_SCHEMA = {
    "type": "ARRAY",
    "description": "An array of up to 10 key news items.",
    "items": {
        "type": "OBJECT",
        "properties": {
            "title": { "type": "STRING", "description": "The main headline of the news item." },
            "summary": { "type": "STRING", "description": "A concise summary of the news item, suitable for display on a web page." },
            "sources": {
                "type": "ARRAY",
                "description": "An array of web sources/citations used to generate the summary.",
                "items": {
                    "type": "OBJECT",
                    "properties": {
                        "link_title": { "type": "STRING", "description": "The title of the source link." },
                        "url": { "type": "STRING", "description": "The full URL of the source." }
                    },
                    "required": ["link_title", "url"]
                }
            }
        },
        "required": ["title", "summary", "sources"]
    }
}


def fetch_and_store_news(country: str, languages: list):
    """
    Fetches the top 10 discussed news items for a country in specified languages
    using the Gemini API with Google Search grounding, and saves the structured
    results to Firestore.

    :param country: The country to query news for (e.g., "France").
    :param languages: A list of languages for the response (e.g., ["English", "French"]).
    """
    if not GEMINI_API_KEY:
        print("ERROR: GEMINI_API_KEY is not set. Cannot proceed with API calls.")
        return

    user_query = f"What are the top 10 most discussed news items right now for {country}? For each item, provide a concise summary. The summary MUST include links to at least one primary source in the required 'sources' array field."

    # Base configuration for the structured API call
    base_payload = {
        "contents": [{ "parts": [{ "text": user_query }] }],
        # Enable Google Search grounding
        "tools": [{ "google_search": {} }],
        "config": {
            # Request JSON output
            "responseMimeType": "application/json",
            "responseSchema": NEWS_SCHEMA
        },
    }

    results = {}

    for lang in languages:
        print(f"\n========================================================")
        print(f"QUERYING NEWS for '{country}' in language: {lang}")
        print(f"========================================================")

        # 1. Update system instruction to ensure response is in the target language
        system_instruction = (
            f"You are a helpful news curator. Your task is to provide the requested information "
            f"strictly in the requested JSON format and ensure all output text is in the {lang} language. "
            f"Ensure to find authoritative and up-to-date sources for all summaries and include them in the 'sources' array."
        )

        payload = base_payload.copy()
        payload["config"]["systemInstruction"] = system_instruction

        try:
            # 2. Execute the API Call with exponential backoff for robustness
            max_retries = 5
            for attempt in range(max_retries):
                response = requests.post(
                    f"{GEMINI_API_URL}?key={GEMINI_API_KEY}",
                    headers={"Content-Type": "application/json"},
                    data=json.dumps(payload),
                    timeout=30 # Set a reasonable timeout
                )

                if response.status_code == 200:
                    break
                elif response.status_code == 429 and attempt < max_retries - 1:
                    wait_time = 2 ** attempt
                    print(f"Rate limit hit (429). Retrying in {wait_time}s...")
                    time.sleep(wait_time)
                else:
                    response.raise_for_status()

            # 3. Process the response
            response_data = response.json()

            # Extract the raw JSON string from the model's response part
            json_text = response_data['candidates'][0]['content']['parts'][0]['text']

            # Parse the JSON string into a Python object
            news_items = json.loads(json_text)

            # 4. Prepare data for Firestore
            firestore_data = {
                "country": country,
                "language": lang,
                "timestamp": datetime.now().isoformat(),
                "news_data": news_items
            }

            # 5. Save to Firestore
            # The actual path should be defined according to your security rules
            # We are using a simple collection name here.
            doc_id = db.collection("news_summaries").add(firestore_data)

            print(f"✅ Successfully fetched and stored news for {country} in {lang}. Document ID: {doc_id}")
            results[lang] = {"status": "success", "doc_id": doc_id, "items_count": len(news_items)}

        except requests.exceptions.HTTPError as e:
            print(f"❌ HTTP Error for {lang}: {e}. Response: {response.text}")
            results[lang] = {"status": "error", "message": f"HTTP Error: {e.response.status_code}"}
        except Exception as e:
            print(f"❌ An error occurred for {lang}: {e}")
            results[lang] = {"status": "error", "message": str(e)}

    return results

# --- EXAMPLE USAGE ---
if __name__ == '__main__':

    COUNTRY_TO_SEARCH = "Japan"
    TARGET_LANGUAGES = ["English", "Japanese"] # Note: Model will output the JSON text in this language

    print(f"Starting news fetcher for {COUNTRY_TO_SEARCH} in {TARGET_LANGUAGES}...")

    final_results = fetch_and_store_news(
        country=COUNTRY_TO_SEARCH,
        languages=TARGET_LANGUAGES
    )

    print("\n\nFINAL RUN SUMMARY:")
    print(json.dumps(final_results, indent=2))

    print("\nIf this were a real run, check your Firestore 'news_summaries' collection!")
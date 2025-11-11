import requests
import json
import time
from datetime import datetime

# Import for the Google GenAI SDK and types
from google import genai
from google.genai import types

# Import for Firebase/Firestore
import firebase_admin
from firebase_admin import credentials, firestore
from firebase_admin.firestore import Query

# --- CONFIGURATION (Replace with your actual settings) ---
# NOTE: The client handles the API key, typically from the GEMINI_API_KEY env var,
# or you can pass it to the client initialization.
GEMINI_API_KEY = "x" # No longer needed directly for client
FIREBASE_PROJECT_ID = "gemini-journalist-8c449"

# --- FIREBASE / GOOGLE CLOUD AUTH SETUP ---

try:
    cred = credentials.Certificate("x.json")
    firebase_admin.initialize_app(cred)
except Exception as e:
    print("Error connecting to Firebase: " + e)

db = firestore.client()

# Initialize the Gemini Client
# It will automatically look for the GEMINI_API_KEY environment variable.
try:
    gemini_client = genai.Client(api_key=GEMINI_API_KEY)
    print("Gemini Client initialized successfully.")
except Exception as e:
    print(f"ERROR: Failed to initialize Gemini Client. Ensure your API key is set as an environment variable (GEMINI_API_KEY). {e}")
    # Create a mock client if initialization fails
    class GeminiClientMock:
        def models(self): return self
        def generate_content(self, model, contents, config):
            print("\n--- MOCK: Gemini API call failed. Returning dummy data. ---")
            return types.GenerateContentResponse(
                text='[{"title": "Mock News Title", "summary": "This is a mock summary.", "sources": [{"link_title": "Mock Source", "url": "http://mock.com"}]}]',
                candidates=[types.Candidate(content=types.Content(parts=[types.Part(text='[{"title": "Mock News Title", "summary": "This is a mock summary.", "sources": [{"link_title": "Mock Source", "url": "http://mock.com"}]}]')]))]
            )
    gemini_client = GeminiClientMock()

# --- JSON Response Schema Definition (For Structured Output) ---
# The google-genai SDK requires the schema to be defined using SDK types
# For simplicity, we use the raw JSON schema but this should ideally be
# built using types.Schema for the SDK. The SDK can often infer from the
# Python types, but for complex structures, we'll keep the string definition
# and adapt the config usage.

# Converting the previous JSON schema definition into a types.Schema object
NEWS_SCHEMA = types.Schema(
    type=types.Type.ARRAY,
    description="An array of up to 10 key news items.",
    items=types.Schema(
        type=types.Type.OBJECT,
        properties={
            "title": types.Schema(type=types.Type.STRING, description="The main headline of the news item."),
            "summary": types.Schema(type=types.Type.STRING, description="A concise summary of the news item, suitable for display on a web page."),
            "sources": types.Schema(
                type=types.Type.ARRAY,
                description="An array of web sources/citations used to generate the summary.",
                items=types.Schema(
                    type=types.Type.OBJECT,
                    properties={
                        "link_title": types.Schema(type=types.Type.STRING, description="The title of the source link."),
                        "url": types.Schema(type=types.Type.STRING, description="The full URL of the source.")
                    },
                    required=["link_title", "url"]
                )
            )
        },
        required=["title", "summary", "sources"]
    )
)


def fetch_and_store_news(country: str, languages: list):
    """
    Fetches the top 10 discussed news items for a country in specified languages
    using the Gemini SDK with Google Search grounding, and saves the structured
    results to Firestore.
    """

    # 1. Define the core user query
    user_query = f"What are the top 10 most discussed news items right now for {country}? For each item, provide a concise summary. The summary MUST include links to at least one primary source in the required 'sources' array field."

    results = {}

    for lang in languages:
        print(f"\n========================================================")
        print(f"QUERYING NEWS for '{country}' in language: {lang}")
        print(f"========================================================")

        # 2. Define the System Instruction for the current language
        system_instruction = (
            f"You are a helpful news curator. Your task is to provide the requested information. "
            f"**Your entire response MUST be a single JSON array (with fields title, summary, and sources(link_title, url)) wrapped in ```json ... ``` code fences.** "
            f"Ensure all output text is in the {lang} language. "
            f"Use the search tool to find authoritative and up-to-date sources and include them in the 'sources' array."
        )

        # 3. Create the GenerateContentConfig object
        config = types.GenerateContentConfig(
            # Pass the System Instruction here
            system_instruction=system_instruction,

            # Enable Google Search grounding
            tools=[{"googleSearch": {}}],

            # Request JSON output
            #response_mime_type="application/json",

            # Pass the structured schema
            #response_schema=NEWS_SCHEMA
        )

        try:
            # 4. Execute the API Call using the SDK
            # The SDK handles retries automatically up to a point.
            response = gemini_client.models.generate_content(
                model="gemini-2.5-flash",
                contents=user_query,
                config=config,
            )

            # 5. Process the response
            # response.text will contain the JSON block wrapped in markdown fences
            raw_text = response.text

            # Extract the raw JSON string by stripping the markdown code fences
            if raw_text.startswith('```json'):
                json_text = raw_text.strip().replace('```json\n', '').replace('\n```', '')
            else:
                json_text = raw_text.strip() # Fallback for a clean output

            news_items = json.loads(json_text)

            # 6. Prepare data for Firestore
            firestore_data = {
                "country": country,
                "language": lang,
                "timestamp": datetime.now().isoformat(),
                "news_data": news_items
            }

            # 7. Save to Firestore
            doc_ref = db.collection("news_summaries").add(firestore_data)
            doc_id = doc_ref[1].id if isinstance(doc_ref, tuple) else doc_ref

            print(f"✅ Successfully fetched and stored news for {country} in {lang}. Document ID: {doc_id}")
            results[lang] = {"status": "success", "doc_id": doc_id, "items_count": len(news_items)}

        except Exception as e:
            # Handle SDK-related errors
            print(f"❌ An error occurred for {lang}: {e}")
            results[lang] = {"status": "error", "message": str(e)}

    return results

# --- EXAMPLE USAGE ---
if __name__ == '__main__':
    COUNTRY_TO_SEARCH = "Japan"
    TARGET_LANGUAGES = ["English", "Japanese"]

    print(f"Starting news fetcher for {COUNTRY_TO_SEARCH} in {TARGET_LANGUAGES}...")

    final_results = fetch_and_store_news(
        country=COUNTRY_TO_SEARCH,
        languages=TARGET_LANGUAGES
    )

    print("\n\nFINAL RUN SUMMARY:")
    print(json.dumps(final_results, indent=2))

    print("\nIf this were a real run, check your Firestore 'news_summaries' collection!")

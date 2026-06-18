# cd '' && '/usr/local/bin/python3'  'gemini_journalist_with_categories.py'
import requests
import json
import re
import time
from datetime import datetime, timezone
from urllib.parse import urlparse

# Import for the Google GenAI SDK and types
from google import genai
from google.genai import types

# Import for Firebase/Firestore
import firebase_admin
from firebase_admin import credentials, firestore
from firebase_admin.firestore import Query

# --- CONFIGURATION (Replace with your actual settings) ---
GEMINI_API_KEY = "x"
FIREBASE_PROJECT_ID = "gemini-journalist-8c449"

# --- FIREBASE / GOOGLE CLOUD AUTH SETUP ---
try:
    cred = credentials.Certificate("gemini-journalist-8c449-firebase-adminsdk-fbsvc-7bbb8af864.json")
    firebase_admin.initialize_app(cred)
except Exception as e:
    print("Error connecting to Firebase: " + str(e))

db = firestore.client()

# Initialize the Gemini Client
try:
    gemini_client = genai.Client(api_key=GEMINI_API_KEY)
    print("Gemini Client initialized successfully.")
except Exception as e:
    print(f"ERROR: Failed to initialize Gemini Client. Ensure your API key is set as an environment variable (GEMINI_API_KEY). {e}")
    class GeminiClientMock:
        def models(self): return self
        def generate_content(self, model, contents, config):
            print("\n--- MOCK: Gemini API call failed. Returning dummy data. ---")
            return types.GenerateContentResponse(
                text='[{"title": "Mock News Title", "summary": "This is a mock summary.", "sources": [{"link_title": "Mock Source", "url": "http://mock.com"}]}]',
                candidates=[types.Candidate(content=types.Content(parts=[types.Part(text='[{"title": "Mock News Title", "summary": "This is a mock summary.", "sources": [{"link_title": "Mock Source", "url": "http://mock.com"}]}]')]))]
            )
    gemini_client = GeminiClientMock()

# Strip links down to their base url
def get_base_url(url: str):
    """Strips a URL down to just the scheme and domain."""
    try:
        parts = urlparse(url)
        base = f"{parts.scheme}://{parts.netloc.replace('www.', '')}"
        if not parts.scheme:
            return f"https://{parts.netloc.replace('www.', '')}"
        return base
    except Exception:
        return url

# --- RETRY CONFIGURATION ---
MAX_RETRIES = 20
INITIAL_WAIT_TIME = 10 # seconds

def safe_json_load(text: str):
    """Robustly attempts to extract and decode a JSON object from text."""
    match = re.search(r'```json\s*(.*?)\s*```', text, re.DOTALL)
    if match:
        json_content = match.group(1).strip()
    else:
        json_content = text.strip()
    return json.loads(json_content)

def _fetch_category_data(category_name: str, query: str, system_instruction: str, country: str, lang: str):
    """Helper function to execute a single Gemini query with retry logic and URL stripping."""
    config = types.GenerateContentConfig(
        system_instruction=system_instruction,
        tools=[{"googleSearch": {}}],
    )

    current_wait_time = INITIAL_WAIT_TIME
    response = None

    for attempt in range(MAX_RETRIES):
        try:
            response = gemini_client.models.generate_content(
                model="gemini-2.5-flash",
                contents=query,
                config=config,
            )

            if not response or not response.text:
                if attempt < MAX_RETRIES - 1:
                    print(f"⚠️ [{category_name}] Attempt {attempt + 1}/{MAX_RETRIES} failed: No text. Retrying in {current_wait_time}s...")
                    time.sleep(current_wait_time)
                    current_wait_time *= 2
                    continue
                else:
                    return None, f"Model returned no text after {MAX_RETRIES} retries."
            break

        except Exception as e:
            error_message = str(e)
            if any(err in error_message for err in ["502", "503", "500"]) and attempt < MAX_RETRIES - 1:
                print(f"⚠️ [{category_name}] Attempt {attempt + 1}/{MAX_RETRIES} failed with transient error ({error_message[:30]}...). Retrying in {current_wait_time}s...")
                time.sleep(current_wait_time)
                current_wait_time *= 2
            else:
                return None, error_message

    if not response or not response.text:
        return None, "Response empty"

    try:
        news_items = safe_json_load(response.text)
        if not news_items:
            return None, "Parsed JSON structure was empty."

        # Strip URLs down to base domains
        if isinstance(news_items, dict) and 'news_items' in news_items:
            for item in news_items['news_items']:
                if 'sources' in item:
                    for source in item['sources']:
                        if 'url' in source:
                            source['url'] = get_base_url(source['url'])

        return news_items, None

    except Exception as e:
        return None, f"JSON parsing/processing error: {str(e)}"


def fetch_and_store_news(country: str, languages: list):
    """
    Fetches news across multiple categories (including Headlines) using Gemini Search grounding,
    combines them into a single payload, and writes it once to Firestore per language.
    """
    results = {}

    for lang in languages:
        print(f"\n========================================================")
        print(f"STARTING COMPREHENSIVE NEWS FETCH FOR '{country}' [{lang}]")
        print(f"========================================================")

        # Base prompt snippet for required source mapping
        source_suffix = "For each item, provide a concise summary. The summary MUST include links to at least one primary source in the required 'sources' array field."

        # Mapping of Category Name -> Targeted User Query
        categories_to_fetch = {
            "Headlines": f"What are the top 10 most discussed news items right now for {country}? {source_suffix}",
            "Business and Markets": f"What are the top 5 most discussed news items right now for {country} in the world of Business and Markets? {source_suffix}",
            "Politics": f"What are the top 5 most discussed news items right now for {country} in the world of Politics? {source_suffix}",
            "Art and Culture": f"What are the top 5 most discussed news items right now for {country} in the world of Art and Culture? {source_suffix}",
            "Sports": f"What are the top 5 most discussed news items right now for {country} in the world of Sports? {source_suffix}",
            "Science and Technology": f"What are the top 5 most discussed news items right now for {country} in the world of Science and Technology? {source_suffix}"
        }

        # System instructions dynamically sizing arrays based on category requirements
        system_instruction_headlines = (
            f"You are a helpful news curator. Your task is to provide 10 current individual news stories, if possible. "
            f"**Your entire response MUST be a single valid JSON structure (with fields title, summary, and sources(link_title, url)) wrapped in ```json ... ``` code fences.** "
            f"Call the JSON news_items. Ensure all output text is in the English language. "
            f"Use the search tool to find authoritative and up-to-date sources and include them in the 'sources' array. "
            f"Do not add anything after the base url for the source. For example: https://apnews.com/<DO NOT ADD ANYTHING HERE> "
            f"Do not use any article that is more than 1 week old."
        )

        system_instruction_categories = (
            f"You are a helpful news curator. Your task is to provide 5 current individual news stories, if possible. "
            f"**Your entire response MUST be a single valid JSON structure (with fields title, summary, and sources(link_title, url)) wrapped in ```json ... ``` code fences.** "
            f"Call the JSON news_items. Ensure all output text is in the English language. "
            f"Use the search tool to find authoritative and up-to-date sources and include them in the 'sources' array. "
            f"Do not add anything after the base url for the source. For example: https://apnews.com/<DO NOT ADD ANYTHING HERE> "
            f"Do not use any article that is more than 1 week old."
        )

        consolidated_news_data = {}
        has_failed_category = False

        # Loop through each category sequentially
        for category, query in categories_to_fetch.items():
            print(f"Fetching category: {category}...")

            # Match the correct prompt length parameters
            sys_instruction = system_instruction_headlines if category == "Headlines" else system_instruction_categories

            news_items, error_msg = _fetch_category_data(category, query, sys_instruction, country, lang)

            if error_msg:
                print(f"❌ Error during category '{category}': {error_msg}")
                log_query_error_to_firestore(country, lang, f"Category [{category}] failed: {error_msg}")
                has_failed_category = True
                break # Break out of category loop for this language if a query completely fails

            # Store the nested content directly into our payload dict
            consolidated_news_data[category] = news_items

        if has_failed_category:
            results[lang] = {"status": "error", "message": "One or more categories failed to gather completely."}
            continue

        try:
            # Language localization identifier adjustment
            lang_code = "en" if lang == "English" else ("es" if lang == "Spanish" else lang)

            # Structure our single, comprehensive firestore document
            firestore_payload = {
                "country": country,
                "language": lang_code,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "news_data": consolidated_news_data
            }

            # Write once to Firestore
            doc_ref = db.collection("news_summaries").add(firestore_payload)
            doc_id = doc_ref[1].id if isinstance(doc_ref, tuple) else doc_ref

            print(f"✅ Document complete! Successfully wrote all combined metrics to Firestore. ID: {doc_id}")
            results[lang] = {"status": "success", "doc_id": doc_id, "categories_included": list(consolidated_news_data.keys())}

        except Exception as e:
            error_msg = f"Firestore Write Failure: {str(e)}"
            print(f"❌ {error_msg}")
            log_query_error_to_firestore(country, lang, error_msg)
            results[lang] = {"status": "error", "message": error_msg}

    return results

def log_query_error_to_firestore(country, lang, error_message):
    """Logs persistent errors into a isolated collection."""
    try:
        error_data = {
            "country": country,
            "language": lang,
            "error_message": error_message,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "status": "persistent_failure"
        }
        db.collection("gemini_query_errors").add(error_data)
        print(f"⚠️ Error trace appended to Firebase logs.")
    except Exception as firestore_e:
        print(f"❌ Failed to log error to Firestore: {firestore_e}")

# --- EXAMPLE USAGE ---
if __name__ == '__main__':
    COUNTRY_TO_SEARCH = "US"
    TARGET_LANGUAGES = ["English"]

    print(f"Starting aggregated category fetcher for {COUNTRY_TO_SEARCH} in {TARGET_LANGUAGES}...")

    final_results = fetch_and_store_news(
        country=COUNTRY_TO_SEARCH,
        languages=TARGET_LANGUAGES
    )

    print("\n\nRUN SUMMARY:")
    print(json.dumps(final_results, indent=2))

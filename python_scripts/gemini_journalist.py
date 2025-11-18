import requests
import json
import re
import time
from datetime import datetime, timezone

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
    cred = credentials.Certificate("gemini-journalist-8c449-firebase-adminsdk-fbsvc-7bbb8af864.json")
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

# --- NEW: RETRY CONFIGURATION ---
MAX_RETRIES = 5
INITIAL_WAIT_TIME = 5 # seconds

def safe_json_load(text: str):
    """
    Robsutly attempts to extract and decode a JSON object from text generated
    by a language model. This addresses the encountered anomalies:

    1. Preamble/Postamble Text (Libya/Marshall Islands): Uses regex to
       extract only the content within ```json ... ``` blocks.
    2. Missing Delimiter (Iran): Ensures only the intended JSON is passed
       to the parser, minimizing external corruption errors.
    """
    # 1. Use regex to find the content inside the first ```json ... ``` block.
    # re.DOTALL is crucial to match newlines within the JSON content.
    match = re.search(r'```json\s*(.*?)\s*```', text, re.DOTALL)

    if match:
        json_content = match.group(1).strip()
    else:
        # If no markdown fences are found, assume the entire text is the JSON
        # (This is necessary for older models or prompts that don't enforce fences)
        json_content = text.strip()

    # 2. Attempt standard JSON decoding on the cleaned content.
    return json.loads(json_content)

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
            f"**Your entire response MUST be a single valid JSON structure (with fields title, summary, and sources(link_title, url)) wrapped in ```json ... ``` code fences.** "
            f"Ensure all output text is in the {lang} language. "
            f"Use the search tool to find authoritative and up-to-date sources and include them in the 'sources' array."
            f"Make sure to link to the original news article that is being referenced on its website."
            f"Do not include news that is over 1 week old. If that means there are not 10 total news headlines, that is OK."
        )


        # 3. Create the GenerateContentConfig object
        config = types.GenerateContentConfig(
            # Pass the System Instruction here
            system_instruction=system_instruction,

            # Enable Google Search grounding
            tools=[{"googleSearch": {}}],
        )

        # --- START OF RETRY LOGIC (New) ---
        response = None
        current_wait_time = INITIAL_WAIT_TIME

        for attempt in range(MAX_RETRIES):
            try:
                # 4. Execute the API Call using the SDK
                response = gemini_client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=user_query,
                    config=config,
                )

                # Check for empty response text (the "None" case)
                if not response or not response.text:
                    # If this is not the last attempt, trigger the retry/backoff
                    if attempt < MAX_RETRIES - 1:
                        print(f"⚠️ Attempt {attempt + 1}/{MAX_RETRIES} failed: Model returned no text. Retrying in {current_wait_time} seconds...")
                        time.sleep(current_wait_time)
                        current_wait_time *= 2  # Exponential backoff
                        continue # Skip to the next iteration (retry)
                    else:
                        # Max retries hit for empty response
                        print(f"❌ Final attempt failed for {lang}: Model returned no text after {MAX_RETRIES} retries.")
                        break # Exit the loop, response remains None/empty

                # If we get a response, break out of the retry loop
                break
            except Exception as e:
                error_message = str(e)
                # Check for 503 UNAVAILABLE (or other transient errors like 500)
                if ("503 UNAVAILABLE" in error_message or "500 INTERNAL_SERVER_ERROR" in error_message) and attempt < MAX_RETRIES - 1:
                    print(f"⚠️ Attempt {attempt + 1}/{MAX_RETRIES} failed with 503/500. Retrying in {current_wait_time} seconds...")
                    time.sleep(current_wait_time)
                    current_wait_time *= 2  # Exponential backoff
                else:
                    # Handle non-retryable errors (e.g., Auth, Invalid Argument, or max retries hit)
                    print(f"❌ A persistent error occurred for {lang}: {e}")
                    results[lang] = {"status": "error", "message": error_message}
                    return results # Exit the language loop on a persistent error

        # Check if the retry loop failed to get a response
        if not response:
            print(f"❌ Max retries reached for {country} in {lang}. Skipping.")
            return results

        # --- END OF RETRY LOGIC (New) ---

        # 5. Process the response (Now robustly handles None and JSON extraction)
        news_items = safe_json_load(response.text)

        # --- ROBUST JSON CHECK (New) ---
        if not news_items:
            error_msg = "Model returned no text (response was empty or blocked). This is the cause of the 'NoneType' error."
            print(f"❌ An error occurred for {lang}: {error_msg}")
            results[lang] = {"status": "error", "message": error_msg}
            continue # Move to the next language

        try:
            # 6. Prepare data for Firestore
            firestore_data = {
                "country": country,
                "language": lang,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "news_data": news_items
            }

            # 7. Save to Firestore
            doc_ref = db.collection("news_summaries").add(firestore_data)
            doc_id = doc_ref[1].id if isinstance(doc_ref, tuple) else doc_ref

            print(f"✅ Successfully fetched and stored news for {country} in {lang}. Document ID: {doc_id}")
            results[lang] = {"status": "success", "doc_id": doc_id, "items_count": len(news_items)}

        except json.JSONDecodeError as e:
            # Handle JSON parsing specific errors
            error_msg = f"JSON Decode Error: {e}. Raw text was: {json.dumps(raw_text, indent=2)}..."
            print(f"❌ An error occurred during JSON parsing for {lang}: {error_msg}")
            results[lang] = {"status": "error", "message": error_msg}
        except ValueError as e:
            # Handle the specific ValueError we raised for empty json_text
            print(f"❌ An error occurred for {lang}: {e}")
            results[lang] = {"status": "error", "message": str(e)}
        except Exception as e:
            # Catch any other unexpected exceptions during processing/Firestore upload
            print(f"❌ An unexpected error occurred for {lang}: {e}")
            results[lang] = {"status": "error", "message": str(e)}

    return results

# --- EXAMPLE USAGE ---
if __name__ == '__main__':
    COUNTRY_TO_SEARCH = "United States of America"
    TARGET_LANGUAGES = ["English", "Spanish"]

    print(f"Starting news fetcher for {COUNTRY_TO_SEARCH} in {TARGET_LANGUAGES}...")

    final_results = fetch_and_store_news(
        country=COUNTRY_TO_SEARCH,
        languages=TARGET_LANGUAGES
    )

    print("\n\nRUN SUMMARY:")
    print(json.dumps(final_results, indent=2))

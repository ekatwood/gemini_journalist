import requests
import json
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
            f"Make sure to link to the original news article that is being referenced on its website."
            f"Do not include news that is over 1 week old. If that means there are not 10 total news headlines, that is OK."
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
        raw_text = response.text

        # --- ROBUST JSON CHECK (New) ---
        if not raw_text:
            error_msg = "Model returned no text (response was empty or blocked). This is the cause of the 'NoneType' error."
            print(f"❌ An error occurred for {lang}: {error_msg}")
            results[lang] = {"status": "error", "message": error_msg}
            continue # Move to the next language

        # Extract the raw JSON string by stripping the markdown code fences
        json_text = raw_text.strip()

        # Use lstrip and rstrip to handle various fence formats and surrounding whitespace
        if json_text.startswith('```json'):
            json_text = json_text.lstrip('```json').rstrip('```')
        elif json_text.startswith('```'):
            json_text = json_text.lstrip('```').rstrip('```')

        # Clean up leading/trailing whitespace and newlines after stripping fences
        json_text = json_text.strip()

        try:
            # Final check before load
            if not json_text:
                 raise ValueError("Could not extract valid JSON from model's response text.")

            news_items = json.loads(json_text)

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
country_languages = {
  'Cameroon': ['English'],
  'Indonesia': ['Indonesian'],
  'Iran (Islamic Republic of)': ['Farsi'],
  'Iraq': ['Arabic', 'Kurdish'],
  'Ireland': ['Irish', 'English'],
  'Israel': ['Hebrew', 'Arabic'],
  'Italy': ['Italian'],
  'Jamaica': ['English'],
  'Japan': ['Japanese'],
  'Jordan': ['Arabic'],
  'Kazakhstan': ['Kazakh', 'Russian'],
  'Kenya': ['Swahili', 'English'],
  'Kiribati': ['English'],
  "Korea (Democratic People's Republic of)": ['Korean'],
  'Korea (Republic of)': ['Korean'],
  'Kuwait': ['Arabic'],
  'Kyrgyzstan': ['Kyrgyz', 'Russian'],
  "Lao People's Democratic Republic": ['Lao'],
  'Latvia': ['Latvian'],
  'Lebanon': ['Arabic'],
  'Lesotho': ['Sesotho', 'English'],
  'Liberia': ['English'],
  'Libya': ['Arabic'],
  'Liechtenstein': ['German'],
  'Lithuania': ['Lithuanian'],
  'Luxembourg': ['Luxembourgish', 'French', 'German'],
  'Madagascar': ['Malagasy', 'French'],
  'Malawi': ['Chichewa', 'English'],
  'Malaysia': ['Malay'],
  'Maldives': ['Dhivehi'],
  'Mali': ['French'],
  'Malta': ['Maltese', 'English'],
  'Marshall Islands': ['Marshallese', 'English'],
  'Mauritania': ['Arabic'],
  'Mauritius': ['English', 'French'],
  'Mexico': ['Spanish'],
  'Micronesia (Federated States of)': ['English'],
  'Moldova (Republic of)': ['Romanian'],
  'Monaco': ['French'],
  'Mongolia': ['Mongolian'],
  'Montenegro': ['Montenegrin'],
  'Morocco': ['Arabic', 'Berber'],
  'Mozambique': ['Portuguese'],
  'Myanmar': ['Burmese'],
  'Namibia': ['English'],
  'Nauru': ['English'],
  'Nepal': ['Nepali'],
  'Netherlands': ['Dutch'],
  'New Zealand': ['English', 'Māori'],
  'Nicaragua': ['Spanish'],
  'Niger': ['French'],
  'Nigeria': ['English'],
  'North Macedonia': ['Macedonian'],
  'Norway': ['Norwegian'],
  'Oman': ['Arabic'],
  'Pakistan': ['Urdu', 'English'],
  'Palau': ['English'],
  'Palestine (State of)': ['Arabic'],
  'Panama': ['Spanish'],
  'Papua New Guinea': ['Tok Pisin', 'English', 'Hiri Motu'],
  'Paraguay': ['Spanish', 'Guaraní'],
  'Peru': ['Spanish'],
  'Philippines': ['Filipino', 'English'],
  'Poland': ['Polish'],
  'Portugal': ['Portuguese'],
  'Qatar': ['Arabic'],
  'Romania': ['Romanian'],
  'Russian Federation': ['Russian'],
  'Rwanda': ['Kinyarwanda', 'English', 'French'],
  'Saint Kitts and Nevis': ['English'],
  'Saint Lucia': ['English'],
  'Saint Vincent and the Grenadines': ['English'],
  'Samoa': ['Samoan', 'English'],
  'San Marino': ['Italian'],
  'Sao Tome and Principe': ['Portuguese'],
  'Saudi Arabia': ['Arabic'],
  'Senegal': ['French'],
  'Serbia': ['Serbian'],
  'Seychelles': ['Seychellois Creole', 'English', 'French'],
  'Sierra Leone': ['English'],
  'Singapore': ['English', 'Malay', 'Mandarin Chinese', 'Tamil'],
  'Slovakia': ['Slovak'],
  'Slovenia': ['Slovene'],
  'Solomon Islands': ['English'],
  'Somalia': ['Somali', 'Arabic'],
  'South Africa': ['Afrikaans', 'English', 'Ndebele', 'Northern Sotho', 'Sotho', 'Swati', 'Tsonga', 'Tswana', 'Xhosa', 'Zulu'],
  'South Sudan': ['English'],
  'Spain': ['Spanish'],
  'Sri Lanka': ['Sinhala', 'Tamil'],
  'Sudan': ['Arabic', 'English'],
  'Suriname': ['Dutch'],
  'Sweden': ['Swedish'],
  'Switzerland': ['German', 'French', 'Italian', 'Romansh'],
  'Syrian Arab Republic': ['Arabic'],
  'Tajikistan': ['Tajik'],
  'Tanzania (United Republic of)': ['Swahili', 'English'],
  'Thailand': ['Thai'],
  'Timor-Leste': ['Portuguese'],
  'Togo': ['French'],
  'Tonga': ['English'],
  'Trinidad and Tobago': ['English'],
  'Tunisia': ['Arabic'],
  'Turkey': ['Turkish'],
  'Turkmenistan': ['Russian'],
  'Tuvalu': ['English'],
  'Uganda': ['English', 'Swahili'],
  'Ukraine': ['Ukrainian'],
  'United Arab Emirates': ['Arabic'],
  'United Kingdom of Great Britain and Northern Ireland': ['English'],
  'United States of America': ['English', 'Spanish'],
  'Uruguay': ['Spanish'],
  'Uzbekistan': ['Uzbek'],
  'Vanuatu': ['English', 'French'],
  'Venezuela (Bolivarian Republic of)': ['Spanish'],
  'Viet Nam': ['Vietnamese'],
  'Yemen': ['Arabic'],
  'Zambia': ['English'],
  'Zimbabwe': ['English'],
}
# --- EXAMPLE USAGE ---
if __name__ == '__main__':
    # COUNTRY_TO_SEARCH = "United States of America"
    # TARGET_LANGUAGES = ["English", "Spanish"]
    #
    # print(f"Starting news fetcher for {COUNTRY_TO_SEARCH} in {TARGET_LANGUAGES}...")
    #
    # final_results = fetch_and_store_news(
    #     country=COUNTRY_TO_SEARCH,
    #     languages=TARGET_LANGUAGES
    # )
    #
    # print("\n\nRUN SUMMARY:")
    # print(json.dumps(final_results, indent=2))
    counter = 0
    for country, languages in country_languages.items():
        if(counter == 50):
            break
        # 'country' is the key (e.g., "Afghanistan")
        # 'languages' is the value (e.g., ['Pashto', 'Dari'])

        # These lines simulate the work your original code was doing:
        COUNTRY_TO_SEARCH = country
        TARGET_LANGUAGES = languages

        # 1. Start processing for the current country
        print(f"Starting news fetch for **{COUNTRY_TO_SEARCH}** in {TARGET_LANGUAGES}...")

        # Here is where your fetch_and_store_news(country, languages) call would go
        final_results = fetch_and_store_news(country=COUNTRY_TO_SEARCH, languages=TARGET_LANGUAGES)

        print(f"Finished processing **{COUNTRY_TO_SEARCH}**.")
        print("\n\nRUN SUMMARY:")
        print(json.dumps(final_results, indent=2))

        print("Waiting 3 seconds...")
        time.sleep(3)

        print("---")

        counter += 1
# gcloud_translate.py

import functions_framework
import json
from google.cloud import translate_v2 as translate
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)

# Initialize the Google Cloud Translate client
# It will automatically pick up credentials from the Cloud Function environment.
translate_client = translate.Client()

@functions_framework.http
def translate_news_items(request):
    """
    HTTP Cloud Function to translate a list of news items.

    This version now also translates the 'link_title' within the 'sources' array.
    """
    # Set CORS headers for preflight requests (Dart/Flutter Web)
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    # Set CORS headers for main request
    headers = {
        'Access-Control-Allow-Origin': '*'
    }

    try:
        # 1. Parse the request body
        request_json = request.get_json(silent=True)
        if not request_json:
            raise ValueError("No JSON data provided.")

        news_items = request_json.get('news_items')
        target_language = request_json.get('target_language')

        if not news_items or not target_language:
            raise ValueError("Missing 'news_items' or 'target_language' in request body.")

        translated_items = []

        # 2. Iterate and translate
        for item in news_items:
            original_title = item.get('title', '')
            original_summary = item.get('summary', '')
            original_sources = item.get('sources', [])

            # --- Translate Title ---
            translated_title = ''
            if original_title:
                result_title = translate_client.translate(
                    original_title,
                    target_language=target_language,
                    source_language='en'
                )
                translated_title = result_title['translatedText']

            # --- Translate Summary ---
            translated_summary = ''
            if original_summary:
                result_summary = translate_client.translate(
                    original_summary,
                    target_language=target_language,
                    source_language='en'
                )
                translated_summary = result_summary['translatedText']

            # --- Translate Source Titles (New Logic) ---
            translated_sources = []
            for source in original_sources:
                original_link_title = source.get('link_title', '')

                translated_link_title = original_link_title
                if original_link_title:
                    result_source_title = translate_client.translate(
                        original_link_title,
                        target_language=target_language,
                        source_language='en'
                    )
                    translated_link_title = result_source_title['translatedText']

                # Reconstruct the source object with the translated title and original URL
                translated_sources.append({
                    'link_title': translated_link_title,
                    'url': source.get('url', '') # URL remains untranslated
                })

            # 3. Create the new translated item
            translated_item = {
                'title': translated_title,
                'summary': translated_summary,
                'sources': translated_sources
            }
            translated_items.append(translated_item)

        # 4. Return the translated list as JSON
        return (json.dumps(translated_items), 200, headers)

    except ValueError as e:
        logging.error(f"Bad Request Error: {e}")
        return (json.dumps({'error': str(e)}), 400, headers) # Bad Request
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}", exc_info=True)
        return (json.dumps({'error': f"Internal Server Error: {str(e)}"}), 500, headers)
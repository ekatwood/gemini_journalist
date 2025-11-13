# gcloud_translate.py

import functions_framework
import json
from google.cloud import translate_v2 as translate

# Initialize the Google Cloud Translate client
# It will automatically pick up credentials from the Cloud Function environment.
translate_client = translate.Client()

@functions_framework.http
def translate_news_items(request):
    """
    HTTP Cloud Function to translate a list of news items.

    Args:
        request (flask.Request): The request object.
        The request body must be a JSON object with:
        {
          "news_items": [
            {"title": "...", "summary": "...", "sources": ["..."]},
            ...
          ],
          "target_language": "es" // e.g., 'es', 'fr'
        }
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

            # Translate Title
            if original_title:
                result_title = translate_client.translate(
                    original_title,
                    target_language=target_language,
                    source_language='en' # Assuming the source from the database is English
                )
                translated_title = result_title['translatedText']
            else:
                translated_title = ''

            # Translate Summary
            if original_summary:
                result_summary = translate_client.translate(
                    original_summary,
                    target_language=target_language,
                    source_language='en'
                )
                translated_summary = result_summary['translatedText']
            else:
                translated_summary = ''

            # Create the new translated item (sources are not translated)
            translated_item = {
                'title': translated_title,
                'summary': translated_summary,
                'sources': item.get('sources', [])
            }
            translated_items.append(translated_item)

        # 3. Return the translated list as JSON
        return (json.dumps(translated_items), 200, headers)

    except ValueError as e:
        return (json.dumps({'error': str(e)}), 400, headers) # Bad Request
    except Exception as e:
        # Log the full error for debugging
        print(f"An unexpected error occurred: {e}")
        return (json.dumps({'error': f"Internal Server Error: {str(e)}"}), 500, headers)
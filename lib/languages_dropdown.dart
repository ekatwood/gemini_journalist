/// A model class to hold a language's code and its full name for display.
class Language {
  final String code; // e.g., 'en' - Used for translation API calls.
  final String name; // e.g., 'English' - Used for UI display.

  const Language({
    required this.code,
    required this.name,
  });
}

const Map<String, String> languageCodeToNameMap = {
  'af': 'Afrikaans',
  'sq': 'Shqip (Albanian)',
  'am': 'አማርኛ (Amharic)',
  'ar': 'العربية (Arabic)',
  'hy': 'Հայերեն (Armenian)',
  'ay': 'Aymar aru (Aymara)',
  'az': 'Azərbaycan dili (Azerbaijani)',
  'be': 'Беларуская (Belarusian)',
  'bn': 'বাংলা (Bengali)',
  'ber': 'Tamazight (Berber)',
  'bs': 'Bosanski (Bosnian)',
  'bg': 'Български (Bulgarian)',
  'my': 'မြန်မာဘာသာ (Burmese)',
  'ca': 'Català (Catalan)',
  'ny': 'Chicheŵa (Chichewa)',
  'hr': 'Hrvatski (Croatian)',
  'da': 'Dansk (Danish)',
  'fa-AF': 'دری (Dari)',
  'dv': 'ދިވެހި (Dhivehi)',
  'nl': 'Nederlands (Dutch)',
  'dz': 'རྫོང་ཁ (Dzongkha)',
  'en': 'English',
  'et': 'Eesti (Estonian)',
  'fa': 'فارسی (Farsi/Persian)',
  'fj': 'Vosa Vakaviti (Fijian)',
  'tl': 'Wikang Filipino (Filipino)',
  'fi': 'Suomi (Finnish)',
  'fr': 'Français (French)',
  'ka': 'ქართული (Georgian)',
  'de': 'Deutsch (German)',
  'el': 'Ελληνικά (Greek)',
  'gn': 'Avañe\'ẽ (Guaraní)',
  'ht': 'Kreyòl Ayisyen (Haitian Creole)',
  'iw': 'עברית (Hebrew)',
  'hi': 'Hindi',
  'hu': 'Magyar (Hungarian)',
  'is': 'Íslenska (Icelandic)',
  'id': 'Bahasa Indonesia (Indonesian)',
  'ga': 'Gaeilge (Irish)',
  'it': 'Italiano (Italian)',
  'ja': '日本語 (Japanese)',
  'kk': 'Қазақ тілі (Kazakh)',
  'km': 'ភាសាខ្មែរ (Khmer)',
  'rw': 'Ikinyarwanda (Kinyarwanda)',
  'ko': '한국어 (Korean)',
  'ku': 'Kurdî (Kurdish)',
  'ky': 'Kyrgyzcha (Kyrgyz)',
  'lo': 'ພາສາລາວ (Lao)',
  'la': 'Latina (Latin)',
  'lv': 'Latviešu valoda (Latvian)',
  'lt': 'Lietuvių kalba (Lithuanian)',
  'lb': 'Lëtzebuergesch (Luxembourgish)',
  'mk': 'Македонски (Macedonian)',
  'mi': 'Te reo Māori (Māori)',
  'mg': 'Malagasy',
  'ms': 'Bahasa Melayu (Malay)',
  'mt': 'Malti (Maltese)',
  'mh': 'Kajin M̧ajeļ (Marshallese)',
  'mn': 'Монгол хэл (Mongolian)',
  'ne': 'नेपाली (Nepali)',
  'no': 'Norsk (Norwegian)',
  'ps': 'پښتو (Pashto)',
  'pl': 'Polski (Polish)',
  'pt': 'Português (Portuguese)',
  'qu': 'Runa Simi (Quechua)',
  'ro': 'Română (Romanian)',
  'ru': 'Русский (Russian)',
  'sm': 'Gagana Sāmoa (Samoan)',
  'sr': 'Srpski/Српски (Serbian)',
  'crs': 'Seselwa (Seychellois Creole)',
  'st': 'Sesotho',
  'tn': 'Setswana',
  'sn': 'chiShona (Shona)',
  'sk': 'Slovenčina (Slovak)',
  'sl': 'Slovenščina (Slovene)',
  'so': 'Soomaali (Somali)',
  'es': 'Español (Spanish)',
  'zh': '普通话/Pǔtōnghuà (Standard Chinese/Mandarin)',
  'sw': 'Kiswahili (Swahili)',
  'ss': 'SiSwati (Swati)',
  'sv': 'Svenska (Swedish)',
  'tg': 'тоҷикӣ (Tajik)',
  'ta': 'தமிழ் (Tamil)',
  'th': 'ภาษาไทย (Thai)',
  'ti': 'ትግርኛ (Tigrinya)',
  'to': 'Lea faka-Tonga (Tongan)',
  'ts': 'Xitsonga (Tsonga)',
  'tr': 'Türkçe (Turkish)',
  'tk': 'Türkmençe (Turkmen)',
  'uk': 'Українська (Ukrainian)',
  'ur': 'اردو (Urdu)',
  'uz': 'Oʻzbekcha/Ўзбекча (Uzbek)',
  'vi': 'Tiếng Việt (Vietnamese)',
  'xh': 'isiXhosa (Xhosa)',
  'zu': 'isiZulu (Zulu)'
};

// const Map<String, String> languageCodeToNameMap = {
//   'af': 'Afrikaans',
//   'sq': 'Albanian (Shqip)',
//   'am': 'Amharic (አማርኛ)',
//   'ar': 'Arabic (العربية)',
//   'hy': 'Armenian (Հայերեն)',
//   'ay': 'Aymara (Aymar aru)',
//   'az': 'Azerbaijani (Azərbaycan dili)',
//   'be': 'Belarusian (Беларуская)',
//   'bn': 'Bengali (বাংলা)',
//   'ber': 'Berber (Tamazight)',
//   'bs': 'Bosnian (Bosanski)',
//   'bg': 'Bulgarian (Български)',
//   'my': 'Burmese (မြန်မာဘာသာ)',
//   'ca': 'Catalan (Català)',
//   'ny': 'Chichewa (Chicheŵa)',
//   'hr': 'Croatian (Hrvatski)',
//   'da': 'Danish (Dansk)',
//   'fa-AF': 'Dari (دری)',
//   'dv': 'Dhivehi (ދިވެހި)',
//   'nl': 'Dutch (Nederlands)',
//   'dz': 'Dzongkha (རྫོང་ཁ)',
//   'en': 'English',
//   'et': 'Estonian (Eesti)',
//   'fa': 'Farsi (Persian) (فارسی)',
//   'fj': 'Fijian (Vosa Vakaviti)',
//   'tl': 'Filipino (Wikang Filipino)',
//   'fi': 'Finnish (Suomi)',
//   'fr': 'French (Français)',
//   'ka': 'Georgian (ქართული)',
//   'de': 'German (Deutsch)',
//   'el': 'Greek (Ελληνικά)',
//   'gn': 'Guaraní (Avañe\'ẽ)',
//   'ht': 'Haitian Creole (Kreyòl Ayisyen)',
//   'iw': 'Hebrew (עברית)',
//   'hi': 'Hindi',
//   'hu': 'Hungarian (Magyar)',
//   'is': 'Icelandic (Íslenska)',
//   'id': 'Indonesian (Bahasa Indonesia)',
//   'ga': 'Irish (Gaeilge)',
//   'it': 'Italian (Italiano)',
//   'ja': 'Japanese (日本語)',
//   'kk': 'Kazakh (Қазақ тілі)',
//   'km': 'Khmer (ភាសាខ្មែរ)',
//   'rw': 'Kinyarwanda (Ikinyarwanda)',
//   'ko': 'Korean (한국어)',
//   'ku': 'Kurdish (Kurdî)',
//   'ky': 'Kyrgyz (Кыргызча)',
//   'lo': 'Lao (ພາສາລາວ)',
//   'la': 'Latin (Latina)',
//   'lv': 'Latvian (Latviešu valoda)',
//   'lt': 'Lithuanian (Lietuvių kalba)',
//   'lb': 'Luxembourgish (Lëtzebuergesch)',
//   'mk': 'Macedonian (Македонски)',
//   'mi': 'Māori (Te reo Māori)',
//   'mg': 'Malagasy (Malagasy)',
//   'ms': 'Malay (Bahasa Melayu)',
//   'mt': 'Maltese (Malti)',
//   'mh': 'Marshallese (Kajin M̧ajeļ)',
//   'mn': 'Mongolian (Монгол хэл)',
//   'ne': 'Nepali (नेपाली)',
//   'no': 'Norwegian (Norsk)',
//   'ps': 'Pashto (پښتو)',
//   'pl': 'Polish (Polski)',
//   'pt': 'Portuguese (Português)',
//   'qu': 'Quechua (Runa Simi)',
//   'ro': 'Romanian (Română)',
//   'ru': 'Russian (Русский)',
//   'sm': 'Samoan (Gagana Sāmoa)',
//   'sr': 'Serbian (Srpski/Српски)',
//   'crs': 'Seychellois Creole (Seselwa)',
//   'st': 'Sesotho (Sesotho)',
//   'tn': 'Setswana (Setswana)',
//   'sn': 'Shona (chiShona)',
//   'sk': 'Slovak (Slovenčina)',
//   'sl': 'Slovene (Slovenščina)',
//   'so': 'Somali (Soomaali)',
//   'es': 'Spanish (Español)',
//   'zh': 'Standard Chinese (Mandarin/普通话/Pǔtōnghuà)',
//   'sw': 'Swahili (Kiswahili)',
//   'ss': 'Swati (SiSwati)',
//   'sv': 'Swedish (Svenska)',
//   'tg': 'Tajik (тоҷикӣ)',
//   'ta': 'Tamil (தமிழ்)',
//   'th': 'Thai (ภาษาไทย)',
//   'ti': 'Tigrinya (ትግርኛ)',
//   'to': 'Tongan (Lea faka-Tonga)',
//   'ts': 'Tsonga (Xitsonga)',
//   'tr': 'Turkish (Türkçe)',
//   'tk': 'Turkmen (Türkmençe)',
//   'uk': 'Ukrainian (Українська)',
//   'ur': 'Urdu (اردو)',
//   'uz': 'Uzbek (Oʻzbekcha/Ўзбекча)',
//   'vi': 'Vietnamese (Tiếng Việt)',
//   'xh': 'Xhosa (isiXhosa)',
//   'zu': 'Zulu (isiZulu)'
// };

// NEW REVERSE MAP: Language Name to Code
final Map<String, String> languageNameToCodeMap =
languageCodeToNameMap.map((key, value) {
  // Strip parenthetical content (e.g., 'English' from 'English (en)') for exact name matching
  final cleanName = value.split('(').first.trim();
  return MapEntry(cleanName, key);
});

// ----------------------------------------------------------------------
// FINAL EXPORTED LIST: The ultimate source for your dropdown UI.
// ----------------------------------------------------------------------

/// A constant list of all supported languages, pairing the code for logic
/// with the full name for the UI.
final List<Language> allLanguages = languageCodeToNameMap.entries
    .map((entry) => Language(code: entry.key, name: entry.value))
    .toList();

final Map<String, List<String>> countryLanguages = {
  'AF': ['en', 'ps', 'fa-AF'], // Afghanistan
  'AL': ['en', 'sq'], // Albania
  'DZ': ['en', 'ar', 'ber'], // Algeria
  'AD': ['en', 'ca'], // Andorra
  'AO': ['en', 'pt'], // Angola
  'AG': ['en'], // Antigua and Barbuda
  'AR': ['en', 'es'], // Argentina
  'AM': ['en', 'hy'], // Armenia
  'AU': ['en'], // Australia
  'AT': ['en', 'de'], // Austria
  'AZ': ['en', 'az'], // Azerbaijan
  'BS': ['en'], // Bahamas
  'BH': ['en', 'ar'], // Bahrain
  'BD': ['en', 'bn'], // Bangladesh
  'BB': ['en'], // Barbados
  'BY': ['en', 'be', 'ru'], // Belarus
  'BE': ['en', 'nl', 'fr', 'de'], // Belgium
  'BZ': ['en'], // Belize
  'BJ': ['en', 'fr'], // Benin
  'BT': ['en', 'dz'], // Bhutan
  'BO': ['en', 'es', 'qu', 'ay'], // Bolivia (Plurinational State of)
  'BA': ['en', 'bs', 'hr', 'sr'], // Bosnia and Herzegovina
  'BW': ['en', 'tn'], // Botswana
  'BR': ['en', 'pt'], // Brazil
  'BN': ['en', 'ms'], // Brunei Darussalam
  'BG': ['en', 'bg'], // Bulgaria
  'BF': ['en', 'fr'], // Burkina Faso
  'BI': ['en', 'fr'], // Burundi
  'CV': ['en', 'pt'], // Cabo Verde
  'KH': ['en', 'km'], // Cambodia
  'CM': ['en', 'fr'], // Cameroon
  'CA': ['en', 'fr'], // Canada
  'CF': ['en', 'fr'], // Central African Republic
  'TD': ['en', 'ar', 'fr'], // Chad
  'CL': ['en', 'es'], // Chile
  'CN': ['en', 'zh'], // China
  'CO': ['en', 'es'], // Colombia
  'KM': ['en', 'ar', 'fr'], // Comoros
  'CG': ['en', 'fr'], // Congo (Republic of the)
  'CD': ['en', 'fr'], // Congo (Democratic Republic of the)
  'CR': ['en', 'es'], // Costa Rica
  'CI': ['en', 'fr'], // Côte d'Ivoire
  'HR': ['en', 'hr'], // Croatia
  'CU': ['en', 'es'], // Cuba
  'CY': ['en', 'el', 'tr'], // Cyprus
  'CZ': ['en', 'cz'], // Czechia
  'DK': ['en', 'da'], // Denmark
  'DJ': ['en', 'fr', 'ar'], // Djibouti
  'DM': ['en'], // Dominica
  'DO': ['en', 'es'], // Dominican Republic
  'EC': ['en', 'es'], // Ecuador
  'EG': ['en', 'ar'], // Egypt
  'SV': ['en', 'es'], // El Salvador
  'GQ': ['en', 'es', 'fr', 'pt'], // Equatorial Guinea
  'ER': ['en', 'ti', 'ar'], // Eritrea
  'EE': ['en', 'et'], // Estonia
  'SZ': ['en'], // Eswatini
  'ET': ['en', 'am'], // Ethiopia
  'FJ': ['en', 'fj', 'ur'], // Fiji
  'FI': ['en', 'fi', 'sv'], // Finland
  'FR': ['en', 'fr'], // France
  'GA': ['en', 'fr'], // Gabon
  'GM': ['en'], // Gambia
  'GE': ['en', 'ka'], // Georgia
  'DE': ['en', 'de'], // Germany
  'GH': ['en'], // Ghana
  'GR': ['en', 'el'], // Greece
  'GD': ['en'], // Grenada
  'GT': ['en', 'es'], // Guatemala
  'GN': ['en', 'fr'], // Guinea
  'GW': ['en', 'pt'], // Guinea-Bissau
  'GY': ['en'], // Guyana
  'HT': ['en', 'ht', 'fr'], // Haiti
  'VA': ['en', 'la', 'it', 'fr', 'de'], // Holy See (Vatican City)
  'HN': ['en', 'es'], // Honduras
  'HU': ['en', 'hu'], // Hungary
  'IS': ['en', 'is'], // Iceland
  'IN': ['en', 'hi'], // India
  'ID': ['en', 'id'], // Indonesia
  'IR': ['en', 'fa'], // Iran (Islamic Republic of)
  'IQ': ['en', 'ar', 'ku'], // Iraq
  'IE': ['en', 'ga'], // Ireland
  'IL': ['en', 'iw', 'ar'], // Israel
  'IT': ['en', 'it'], // Italy
  'JM': ['en'], // Jamaica
  'JP': ['en', 'ja'], // Japan
  'JO': ['en', 'ar'], // Jordan
  'KZ': ['en', 'kk', 'ru'], // Kazakhstan
  'KE': ['en', 'sw'], // Kenya
  'KI': ['en'], // Kiribati
  'KP': ['en', 'ko'], // Korea (Democratic People's Republic of)
  'KR': ['en', 'ko'], // Korea (Republic of)
  'KW': ['en', 'ar'], // Kuwait
  'KG': ['en', 'ky', 'ru'], // Kyrgyzstan
  'LA': ['en', 'lo'], // Lao People's Democratic Republic
  'LV': ['en', 'lv'], // Latvia
  'LB': ['en', 'ar'], // Lebanon
  'LS': ['en', 'st'], // Lesotho
  'LR': ['en'], // Liberia
  'LY': ['en', 'ar'], // Libya
  'LI': ['en', 'de'], // Liechtenstein
  'LT': ['en', 'lt'], // Lithuania
  'LU': ['en', 'lb', 'fr', 'de'], // Luxembourg
  'MG': ['en', 'mg', 'fr'], // Madagascar
  'MW': ['en', 'ny'], // Malawi
  'MY': ['en', 'ms'], // Malaysia
  'MV': ['en', 'dv'], // Maldives
  'ML': ['en', 'fr'], // Mali
  'MT': ['en', 'mt'], // Malta
  'MH': ['en', 'mh'], // Marshall Islands
  'MR': ['en', 'ar'], // Mauritania
  'MU': ['en', 'fr'], // Mauritius
  'MX': ['en', 'es'], // Mexico
  'FM': ['en'], // Micronesia (Federated States of)
  'MD': ['en', 'ro'], // Moldova (Republic of)
  'MC': ['en', 'fr'], // Monaco
  'MN': ['en', 'mn'], // Mongolia
  'ME': ['en', 'sr'], // Montenegro
  'MA': ['en', 'ar', 'ber'], // Morocco
  'MZ': ['en', 'pt'], // Mozambique
  'MM': ['en', 'my'], // Myanmar
  'NA': ['en'], // Namibia
  'NR': ['en'], // Nauru
  'NP': ['en', 'ne'], // Nepal
  'NL': ['en', 'nl'], // Netherlands
  'NZ': ['en', 'mi'], // New Zealand
  'NI': ['en', 'es'], // Nicaragua
  'NE': ['en', 'fr'], // Niger
  'NG': ['en'], // Nigeria
  'MK': ['en', 'mk'], // North Macedonia
  'NO': ['en', 'no'], // Norway
  'OM': ['en', 'ar'], // Oman
  'PK': ['en', 'ur'], // Pakistan
  'PW': ['en'], // Palau
  'PS': ['en', 'ar'], // Palestine (State of)
  'PA': ['en', 'es'], // Panama
  'PG': ['en'], // Papua New Guinea
  'PY': ['en', 'es', 'gn'], // Paraguay
  'PE': ['en', 'es'], // Peru
  'PH': ['en', 'tl'], // Philippines
  'PL': ['en', 'pl'], // Poland
  'PT': ['en', 'pt'], // Portugal
  'QA': ['en', 'ar'], // Qatar
  'RO': ['en', 'ro'], // Romania
  'RU': ['en', 'ru'], // Russian Federation
  'RW': ['en', 'rw', 'fr'], // Rwanda
  'KN': ['en'], // Saint Kitts and Nevis
  'LC': ['en'], // Saint Lucia
  'VC': ['en'], // Saint Vincent and the Grenadines
  'WS': ['en', 'sm'], // Samoa
  'SM': ['en', 'it'], // San Marino
  'ST': ['en', 'pt'], // Sao Tome and Principe
  'SA': ['en', 'ar'], // Saudi Arabia
  'SN': ['en', 'fr'], // Senegal
  'RS': ['en', 'sr'], // Serbia
  'SC': ['en', 'crs', 'fr'], // Seychelles
  'SL': ['en'], // Sierra Leone
  'SG': ['en', 'ms', 'zh', 'ta'], // Singapore
  'SK': ['en', 'sk'], // Slovakia
  'SI': ['en', 'sl'], // Slovenia
  'SB': ['en'], // Solomon Islands
  'SO': ['en', 'so', 'ar'], // Somalia
  'ZA': ['en', 'af', 'nr', 'st', 'st', 'ss', 'ts', 'tn', 'xh', 'zu'], // South Africa
  'SS': ['en'], // South Sudan
  'ES': ['en', 'es'], // Spain
  'LK': ['en', 'si', 'ta'], // Sri Lanka
  'SD': ['en', 'ar'], // Sudan
  'SR': ['en', 'nl'], // Suriname
  'SE': ['en', 'sv'], // Sweden
  'CH': ['en', 'de', 'fr', 'it', 'rm'], // Switzerland
  'SY': ['en', 'ar'], // Syrian Arab Republic
  'TJ': ['en', 'tg'], // Tajikistan
  'TZ': ['en', 'sw'], // Tanzania (United Republic of)
  'TH': ['en', 'th'], // Thailand
  'TL': ['en', 'pt'], // Timor-Leste
  'TG': ['en', 'fr'], // Togo
  'TO': ['en'], // Tonga
  'TT': ['en'], // Trinidad and Tobago
  'TN': ['en', 'ar'], // Tunisia
  'TR': ['en', 'tr'], // Turkey
  'TM': ['en', 'ru'], // Turkmenistan
  'TV': ['en'], // Tuvalu
  'UG': ['en', 'sw'], // Uganda
  'UA': ['en', 'uk'], // Ukraine
  'AE': ['en', 'ar'], // United Arab Emirates
  'GB': ['en'], // United Kingdom of Great Britain and Northern Ireland
  'US': ['en', 'es'], // United States of America
  'UY': ['en', 'es'], // Uruguay
  'UZ': ['en', 'uz'], // Uzbekistan
  'VU': ['en', 'fr'], // Vanuatu
  'VE': ['en', 'es'], // Venezuela (Bolivarian Republic of)
  'VN': ['en', 'vi'], // Viet Nam
  'YE': ['en', 'ar'], // Yemen
  'ZM': ['en'], // Zambia
  'ZW': ['en'], // Zimbabwe
};

// final Map<String, List<String>> countryLanguages = {
//   'AF': ['Pashto', 'Dari'], // Afghanistan
//   'AL': ['Albanian'], // Albania
//   'DZ': ['Arabic', 'Berber'], // Algeria
//   'AD': ['Catalan'], // Andorra
//   'AO': ['Portuguese'], // Angola
//   'AG': ['English'], // Antigua and Barbuda
//   'AR': ['Spanish'], // Argentina
//   'AM': ['Armenian'], // Armenia
//   'AU': ['English'], // Australia
//   'AT': ['German'], // Austria
//   'AZ': ['Azerbaijani'], // Azerbaijan
//   'BS': ['English'], // Bahamas
//   'BH': ['Arabic'], // Bahrain
//   'BD': ['Bengali'], // Bangladesh
//   'BB': ['English'], // Barbados
//   'BY': ['Belarusian', 'Russian'], // Belarus
//   'BE': ['Dutch', 'French', 'German'], // Belgium
//   'BZ': ['English'], // Belize
//   'BJ': ['French'], // Benin
//   'BT': ['Dzongkha'], // Bhutan
//   'BO': ['Spanish', 'Quechua', 'Aymara'], // Bolivia (Plurinational State of)
//   'BA': ['Bosnian', 'Croatian', 'Serbian'], // Bosnia and Herzegovina
//   'BW': ['English', 'Setswana'], // Botswana
//   'BR': ['Portuguese'], // Brazil
//   'BN': ['Malay'], // Brunei Darussalam
//   'BG': ['Bulgarian'], // Bulgaria
//   'BF': ['French'], // Burkina Faso
//   'BI': ['French'], // Burundi
//   'CV': ['Portuguese'], // Cabo Verde
//   'KH': ['Khmer'], // Cambodia
//   'CM': ['English', 'French'], // Cameroon
//   'CA': ['English', 'French'], // Canada
//   'CF': ['French'], // Central African Republic
//   'TD': ['Arabic', 'French'], // Chad
//   'CL': ['Spanish'], // Chile
//   'CN': ['Standard Chinese (Mandarin)'], // China
//   'CO': ['Spanish'], // Colombia
//   'KM': ['Arabic', 'French'], // Comoros
//   'CG': ['French'], // Congo (Republic of the)
//   'CD': ['French'], // Congo (Democratic Republic of the)
//   'CR': ['Spanish'], // Costa Rica
//   'CI': ['French'], // Côte d'Ivoire
//   'HR': ['Croatian'], // Croatia
//   'CU': ['Spanish'], // Cuba
//   'CY': ['Greek', 'Turkish'], // Cyprus
//   'CZ': ['Czech'], // Czechia
//   'DK': ['Danish'], // Denmark
//   'DJ': ['French', 'Arabic'], // Djibouti
//   'DM': ['English'], // Dominica
//   'DO': ['Spanish'], // Dominican Republic
//   'EC': ['Spanish'], // Ecuador
//   'EG': ['Arabic'], // Egypt
//   'SV': ['Spanish'], // El Salvador
//   'GQ': ['Spanish', 'French', 'Portuguese'], // Equatorial Guinea
//   'ER': ['Tigrinya', 'Arabic', 'English'], // Eritrea
//   'EE': ['Estonian'], // Estonia
//   'SZ': ['English'], // Eswatini
//   'ET': ['Amharic'], // Ethiopia
//   'FJ': ['Fijian', 'English', 'Urdu'], // Fiji
//   'FI': ['Finnish', 'Swedish'], // Finland
//   'FR': ['French'], // France
//   'GA': ['French'], // Gabon
//   'GM': ['English'], // Gambia
//   'GE': ['Georgian'], // Georgia
//   'DE': ['German'], // Germany
//   'GH': ['English'], // Ghana
//   'GR': ['Greek'], // Greece
//   'GD': ['English'], // Grenada
//   'GT': ['Spanish'], // Guatemala
//   'GN': ['French'], // Guinea
//   'GW': ['Portuguese'], // Guinea-Bissau
//   'GY': ['English'], // Guyana
//   'HT': ['Haitian Creole', 'French'], // Haiti
//   'VA': ['Latin', 'Italian', 'French', 'German'], // Holy See (Vatican City)
//   'HN': ['Spanish'], // Honduras
//   'HU': ['Hungarian'], // Hungary
//   'IS': ['Icelandic'], // Iceland
//   'IN': ['Hindi', 'English'], // India
//   'ID': ['Indonesian'], // Indonesia
//   'IR': ['Farsi'], // Iran (Islamic Republic of)
//   'IQ': ['Arabic', 'Kurdish'], // Iraq
//   'IE': ['Irish', 'English'], // Ireland
//   'IL': ['Hebrew', 'Arabic'], // Israel
//   'IT': ['Italian'], // Italy
//   'JM': ['English'], // Jamaica
//   'JP': ['Japanese'], // Japan
//   'JO': ['Arabic'], // Jordan
//   'KZ': ['Kazakh', 'Russian'], // Kazakhstan
//   'KE': ['Swahili', 'English'], // Kenya
//   'KI': ['English'], // Kiribati
//   'KP': ['Korean'], // Korea (Democratic People's Republic of)
//   'KR': ['Korean'], // Korea (Republic of)
//   'KW': ['Arabic'], // Kuwait
//   'KG': ['Kyrgyz', 'Russian'], // Kyrgyzstan
//   'LA': ['Lao'], // Lao People's Democratic Republic
//   'LV': ['Latvian'], // Latvia
//   'LB': ['Arabic'], // Lebanon
//   'LS': ['Sesotho', 'English'], // Lesotho
//   'LR': ['English'], // Liberia
//   'LY': ['Arabic'], // Libya
//   'LI': ['German'], // Liechtenstein
//   'LT': ['Lithuanian'], // Lithuania
//   'LU': ['Luxembourgish', 'French', 'German'], // Luxembourg
//   'MG': ['Malagasy', 'French'], // Madagascar
//   'MW': ['Chichewa', 'English'], // Malawi
//   'MY': ['Malay'], // Malaysia
//   'MV': ['Dhivehi'], // Maldives
//   'ML': ['French'], // Mali
//   'MT': ['Maltese', 'English'], // Malta
//   'MH': ['Marshallese', 'English'], // Marshall Islands
//   'MR': ['Arabic'], // Mauritania
//   'MU': ['English', 'French'], // Mauritius
//   'MX': ['Spanish'], // Mexico
//   'FM': ['English'], // Micronesia (Federated States of)
//   'MD': ['Romanian'], // Moldova (Republic of)
//   'MC': ['French'], // Monaco
//   'MN': ['Mongolian'], // Mongolia
//   'ME': ['Serbian'], // Montenegro
//   'MA': ['Arabic', 'Berber'], // Morocco
//   'MZ': ['Portuguese'], // Mozambique
//   'MM': ['Burmese'], // Myanmar
//   'NA': ['English'], // Namibia
//   'NR': ['English'], // Nauru
//   'NP': ['Nepali'], // Nepal
//   'NL': ['Dutch'], // Netherlands
//   'NZ': ['English', 'Māori'], // New Zealand
//   'NI': ['Spanish'], // Nicaragua
//   'NE': ['French'], // Niger
//   'NG': ['English'], // Nigeria
//   'MK': ['Macedonian'], // North Macedonia
//   'NO': ['Norwegian'], // Norway
//   'OM': ['Arabic'], // Oman
//   'PK': ['Urdu', 'English'], // Pakistan
//   'PW': ['English'], // Palau
//   'PS': ['Arabic'], // Palestine (State of)
//   'PA': ['Spanish'], // Panama
//   'PG': ['English'], // Papua New Guinea
//   'PY': ['Spanish', 'Guaraní'], // Paraguay
//   'PE': ['Spanish'], // Peru
//   'PH': ['Filipino', 'English'], // Philippines
//   'PL': ['Polish'], // Poland
//   'PT': ['Portuguese'], // Portugal
//   'QA': ['Arabic'], // Qatar
//   'RO': ['Romanian'], // Romania
//   'RU': ['Russian'], // Russian Federation
//   'RW': ['Kinyarwanda', 'English', 'French'], // Rwanda
//   'KN': ['English'], // Saint Kitts and Nevis
//   'LC': ['English'], // Saint Lucia
//   'VC': ['English'], // Saint Vincent and the Grenadines
//   'WS': ['Samoan', 'English'], // Samoa
//   'SM': ['Italian'], // San Marino
//   'ST': ['Portuguese'], // Sao Tome and Principe
//   'SA': ['Arabic'], // Saudi Arabia
//   'SN': ['French'], // Senegal
//   'RS': ['Serbian'], // Serbia
//   'SC': ['Seychellois Creole', 'English', 'French'], // Seychelles
//   'SL': ['English'], // Sierra Leone
//   'SG': ['English', 'Malay', 'Mandarin Chinese', 'Tamil'], // Singapore
//   'SK': ['Slovak'], // Slovakia
//   'SI': ['Slovene'], // Slovenia
//   'SB': ['English'], // Solomon Islands
//   'SO': ['Somali', 'Arabic'], // Somalia
//   'ZA': ['Afrikaans', 'English', 'Ndebele', 'Northern Sotho', 'Sotho', 'Swati', 'Tsonga', 'Tswana', 'Xhosa', 'Zulu'], // South Africa
//   'SS': ['English'], // South Sudan
//   'ES': ['Spanish'], // Spain
//   'LK': ['Sinhala', 'Tamil'], // Sri Lanka
//   'SD': ['Arabic', 'English'], // Sudan
//   'SR': ['Dutch'], // Suriname
//   'SE': ['Swedish'], // Sweden
//   'CH': ['German', 'French', 'Italian', 'Romansh'], // Switzerland
//   'SY': ['Arabic'], // Syrian Arab Republic
//   'TJ': ['Tajik'], // Tajikistan
//   'TZ': ['Swahili', 'English'], // Tanzania (United Republic of)
//   'TH': ['Thai'], // Thailand
//   'TL': ['Portuguese'], // Timor-Leste
//   'TG': ['French'], // Togo
//   'TO': ['English'], // Tonga
//   'TT': ['English'], // Trinidad and Tobago
//   'TN': ['Arabic'], // Tunisia
//   'TR': ['Turkish'], // Turkey
//   'TM': ['Russian'], // Turkmenistan
//   'TV': ['English'], // Tuvalu
//   'UG': ['English', 'Swahili'], // Uganda
//   'UA': ['Ukrainian'], // Ukraine
//   'AE': ['Arabic'], // United Arab Emirates
//   'GB': ['English'], // United Kingdom of Great Britain and Northern Ireland
//   'US': ['English', 'Spanish'], // United States of America
//   'UY': ['Spanish'], // Uruguay
//   'UZ': ['Uzbek'], // Uzbekistan
//   'VU': ['English', 'French'], // Vanuatu
//   'VE': ['Spanish'], // Venezuela (Bolivarian Republic of)
//   'VN': ['Vietnamese'], // Viet Nam
//   'YE': ['Arabic'], // Yemen
//   'ZM': ['English'], // Zambia
//   'ZW': ['English'], // Zimbabwe
// };
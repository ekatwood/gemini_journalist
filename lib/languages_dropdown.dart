/// A model class to hold a language's code and its full name for display.
class Language {
  final String code; // e.g., 'en' - Used for translation API calls.
  final String name; // e.g., 'English' - Used for UI display.

  const Language({
    required this.code,
    required this.name,
  });
}

const Map<String, String> _languageCodeToNameMap = {
  'af': 'Afrikaans',
  'sq': 'Albanian (Shqip)',
  'am': 'Amharic (አማርኛ)',
  'ar': 'Arabic (العربية)',
  'hy': 'Armenian (Հայերեն)',
  'ay': 'Aymara (Aymar aru)',
  'az': 'Azerbaijani (Azərbaycan dili)',
  'be': 'Belarusian (Беларуская)',
  'bn': 'Bengali (বাংলা)',
  'ber': 'Berber (Tamazight)',
  'bs': 'Bosnian (Bosanski)',
  'bg': 'Bulgarian (Български)',
  'my': 'Burmese (မြန်မာဘာသာ)',
  'ca': 'Catalan (Català)',
  'ny': 'Chichewa (Chicheŵa)',
  'hr': 'Croatian (Hrvatski)',
  'prs': 'Dari (دری)',
  'dv': 'Dhivehi (ދިވެހި)',
  'nl': 'Dutch (Nederlands)',
  'en': 'English',
  'et': 'Estonian (Eesti)',
  'fa': 'Farsi (Persian) (فارسی)',
  'fj': 'Fijian (Vosa Vakaviti)',
  'fil': 'Filipino (Wikang Filipino)',
  'fi': 'Finnish (Suomi)',
  'fr': 'French (Français)',
  'ka': 'Georgian (ქართული)',
  'de': 'German (Deutsch)',
  'el': 'Greek (Ελληνικά)',
  'gn': 'Guaraní (Avañe\'ẽ)',
  'ht': 'Haitian Creole (Kreyòl Ayisyen)',
  'iw': 'Hebrew (עברית)',
  'hi': 'Hindi',
  'is': 'Icelandic (Íslenska)',
  'id': 'Indonesian (Bahasa Indonesia)',
  'ga': 'Irish (Gaeilge)',
  'it': 'Italian (Italiano)',
  'ja': 'Japanese (日本語)',
  'kk': 'Kazakh (Қазақ тілі)',
  'km': 'Khmer (ភាសាខ្មែរ)',
  'ko': 'Korean (한국어)',
  'ku': 'Kurdish (Kurdî)',
  'lo': 'Lao (ພາສາລາວ)',
  'la': 'Latin (Latina)',
  'lv': 'Latvian (Latviešu valoda)',
  'lt': 'Lithuanian (Lietuvių kalba)',
  'lb': 'Luxembourgish (Lëtzebuergesch)',
  'mi': 'Māori (Te reo Māori)',
  'mg': 'Malagasy (Malagasy)',
  'ms': 'Malay (Bahasa Melayu)',
  'mt': 'Maltese (Malti)',
  'mh': 'Marshallese (Kajin M̧ajeļ)',
  'mn': 'Mongolian (Монгол хэл)',
  'sr': 'Montenegrin (Crnogorski/Црногорски)',
  'ne': 'Nepali (नेपाली)',
  'no': 'Norwegian (Norsk)',
  'ps': 'Pashto (پښتو)',
  'pl': 'Polish (Polski)',
  'pt': 'Portuguese (Português)',
  'qu': 'Quechua (Runa Simi)',
  'ro': 'Romanian (Română)',
  'ru': 'Russian (Русский)',
  'st': 'Sesotho (Sesotho)',
  'tn': 'Setswana (Setswana)',
  'sn': 'Shona (chiShona)',
  'sk': 'Slovak (Slovenčina)',
  'sl': 'Slovene (Slovenščina)',
  'es': 'Spanish (Español)',
  'zh': 'Standard Chinese (Mandarin/普通话/Pǔtōnghuà)',
  'sw': 'Swahili (Kiswahili)',
  'ss': 'Swati (SiSwati)',
  'sv': 'Swedish (Svenska)',
  'tg': 'Tajik (тоҷикӣ)',
  'th': 'Thai (ภาษาไทย)',
  'ti': 'Tigrinya (ትግርኛ)',
  'tpi': 'Tok Pisin',
  'ts': 'Tsonga (Xitsonga)',
  'tr': 'Turkish (Türkçe)',
  'uk': 'Ukrainian (Українська)',
  'ur': 'Urdu (اردو)',
  'uz': 'Uzbek (Oʻzbekcha/Ўзбекча)',
  'vi': 'Vietnamese (Tiếng Việt)',
  'xh': 'Xhosa (isiXhosa)',
  'zu': 'Zulu (isiZulu)',
};

// ----------------------------------------------------------------------
// FINAL EXPORTED LIST: The ultimate source for your dropdown UI.
// ----------------------------------------------------------------------

/// A constant list of all supported languages, pairing the code for logic
/// with the full name for the UI.
final List<Language> allLanguages = _languageCodeToNameMap.entries
    .map((entry) => Language(code: entry.key, name: entry.value))
    .toList()
// Sort by display name for a better user experience
  ..sort((a, b) => a.name.compareTo(b.name));

final Map<String, List<String>> countryLanguages = {
  'AF': ['Pashto', 'Dari'], // Afghanistan
  'AL': ['Albanian'], // Albania
  'DZ': ['Arabic', 'Berber'], // Algeria
  'AD': ['Catalan'], // Andorra
  'AO': ['Portuguese'], // Angola
  'AG': ['English'], // Antigua and Barbuda
  'AR': ['Spanish'], // Argentina
  'AM': ['Armenian'], // Armenia
  'AU': ['English'], // Australia
  'AT': ['German'], // Austria
  'AZ': ['Azerbaijani'], // Azerbaijan
  'BS': ['English'], // Bahamas
  'BH': ['Arabic'], // Bahrain
  'BD': ['Bengali'], // Bangladesh
  'BB': ['English'], // Barbados
  'BY': ['Belarusian', 'Russian'], // Belarus
  'BE': ['Dutch', 'French', 'German'], // Belgium
  'BZ': ['English'], // Belize
  'BJ': ['French'], // Benin
  'BT': ['Dzongkha'], // Bhutan
  'BO': ['Spanish', 'Quechua', 'Aymara'], // Bolivia (Plurinational State of)
  'BA': ['Bosnian', 'Croatian', 'Serbian'], // Bosnia and Herzegovina
  'BW': ['English', 'Setswana'], // Botswana
  'BR': ['Portuguese'], // Brazil
  'BN': ['Malay'], // Brunei Darussalam
  'BG': ['Bulgarian'], // Bulgaria
  'BF': ['French'], // Burkina Faso
  'BI': ['French'], // Burundi
  'CV': ['Portuguese'], // Cabo Verde
  'KH': ['Khmer'], // Cambodia
  'CM': ['English', 'French'], // Cameroon
  'CA': ['English', 'French'], // Canada
  'CF': ['French'], // Central African Republic
  'TD': ['Arabic', 'French'], // Chad
  'CL': ['Spanish'], // Chile
  'CN': ['Standard Chinese (Mandarin)'], // China
  'CO': ['Spanish'], // Colombia
  'KM': ['Arabic', 'French'], // Comoros
  'CG': ['French'], // Congo (Republic of the)
  'CD': ['French'], // Congo (Democratic Republic of the)
  'CR': ['Spanish'], // Costa Rica
  'CI': ['French'], // Côte d'Ivoire
  'HR': ['Croatian'], // Croatia
  'CU': ['Spanish'], // Cuba
  'CY': ['Greek', 'Turkish'], // Cyprus
  'CZ': ['Czech'], // Czechia
  'DK': ['Danish'], // Denmark
  'DJ': ['French', 'Arabic'], // Djibouti
  'DM': ['English'], // Dominica
  'DO': ['Spanish'], // Dominican Republic
  'EC': ['Spanish'], // Ecuador
  'EG': ['Arabic'], // Egypt
  'SV': ['Spanish'], // El Salvador
  'GQ': ['Spanish', 'French', 'Portuguese'], // Equatorial Guinea
  'ER': ['Tigrinya', 'Arabic', 'English'], // Eritrea
  'EE': ['Estonian'], // Estonia
  'SZ': ['English'], // Eswatini
  'ET': ['Amharic'], // Ethiopia
  'FJ': ['Fijian', 'English', 'Hindustani'], // Fiji
  'FI': ['Finnish', 'Swedish'], // Finland
  'FR': ['French'], // France
  'GA': ['French'], // Gabon
  'GM': ['English'], // Gambia
  'GE': ['Georgian'], // Georgia
  'DE': ['German'], // Germany
  'GH': ['English'], // Ghana
  'GR': ['Greek'], // Greece
  'GD': ['English'], // Grenada
  'GT': ['Spanish'], // Guatemala
  'GN': ['French'], // Guinea
  'GW': ['Portuguese'], // Guinea-Bissau
  'GY': ['English'], // Guyana
  'HT': ['Haitian Creole', 'French'], // Haiti
  'VA': ['Latin', 'Italian', 'French', 'German'], // Holy See (Vatican City)
  'HN': ['Spanish'], // Honduras
  'HU': ['Hungarian'], // Hungary
  'IS': ['Icelandic'], // Iceland
  'IN': ['Hindi', 'English'], // India
  'ID': ['Indonesian'], // Indonesia
  'IR': ['Farsi'], // Iran (Islamic Republic of)
  'IQ': ['Arabic', 'Kurdish'], // Iraq
  'IE': ['Irish', 'English'], // Ireland
  'IL': ['Hebrew', 'Arabic'], // Israel
  'IT': ['Italian'], // Italy
  'JM': ['English'], // Jamaica
  'JP': ['Japanese'], // Japan
  'JO': ['Arabic'], // Jordan
  'KZ': ['Kazakh', 'Russian'], // Kazakhstan
  'KE': ['Swahili', 'English'], // Kenya
  'KI': ['English'], // Kiribati
  'KP': ['Korean'], // Korea (Democratic People's Republic of)
  'KR': ['Korean'], // Korea (Republic of)
  'KW': ['Arabic'], // Kuwait
  'KG': ['Kyrgyz', 'Russian'], // Kyrgyzstan
  'LA': ['Lao'], // Lao People's Democratic Republic
  'LV': ['Latvian'], // Latvia
  'LB': ['Arabic'], // Lebanon
  'LS': ['Sesotho', 'English'], // Lesotho
  'LR': ['English'], // Liberia
  'LY': ['Arabic'], // Libya
  'LI': ['German'], // Liechtenstein
  'LT': ['Lithuanian'], // Lithuania
  'LU': ['Luxembourgish', 'French', 'German'], // Luxembourg
  'MG': ['Malagasy', 'French'], // Madagascar
  'MW': ['Chichewa', 'English'], // Malawi
  'MY': ['Malay'], // Malaysia
  'MV': ['Dhivehi'], // Maldives
  'ML': ['French'], // Mali
  'MT': ['Maltese', 'English'], // Malta
  'MH': ['Marshallese', 'English'], // Marshall Islands
  'MR': ['Arabic'], // Mauritania
  'MU': ['English', 'French'], // Mauritius
  'MX': ['Spanish'], // Mexico
  'FM': ['English'], // Micronesia (Federated States of)
  'MD': ['Romanian'], // Moldova (Republic of)
  'MC': ['French'], // Monaco
  'MN': ['Mongolian'], // Mongolia
  'ME': ['Montenegrin'], // Montenegro
  'MA': ['Arabic', 'Berber'], // Morocco
  'MZ': ['Portuguese'], // Mozambique
  'MM': ['Burmese'], // Myanmar
  'NA': ['English'], // Namibia
  'NR': ['English'], // Nauru
  'NP': ['Nepali'], // Nepal
  'NL': ['Dutch'], // Netherlands
  'NZ': ['English', 'Māori'], // New Zealand
  'NI': ['Spanish'], // Nicaragua
  'NE': ['French'], // Niger
  'NG': ['English'], // Nigeria
  'MK': ['Macedonian'], // North Macedonia
  'NO': ['Norwegian'], // Norway
  'OM': ['Arabic'], // Oman
  'PK': ['Urdu', 'English'], // Pakistan
  'PW': ['English'], // Palau
  'PS': ['Arabic'], // Palestine (State of)
  'PA': ['Spanish'], // Panama
  'PG': ['Tok Pisin', 'English', 'Hiri Motu'], // Papua New Guinea
  'PY': ['Spanish', 'Guaraní'], // Paraguay
  'PE': ['Spanish'], // Peru
  'PH': ['Filipino', 'English'], // Philippines
  'PL': ['Polish'], // Poland
  'PT': ['Portuguese'], // Portugal
  'QA': ['Arabic'], // Qatar
  'RO': ['Romanian'], // Romania
  'RU': ['Russian'], // Russian Federation
  'RW': ['Kinyarwanda', 'English', 'French'], // Rwanda
  'KN': ['English'], // Saint Kitts and Nevis
  'LC': ['English'], // Saint Lucia
  'VC': ['English'], // Saint Vincent and the Grenadines
  'WS': ['Samoan', 'English'], // Samoa
  'SM': ['Italian'], // San Marino
  'ST': ['Portuguese'], // Sao Tome and Principe
  'SA': ['Arabic'], // Saudi Arabia
  'SN': ['French'], // Senegal
  'RS': ['Serbian'], // Serbia
  'SC': ['Seychellois Creole', 'English', 'French'], // Seychelles
  'SL': ['English'], // Sierra Leone
  'SG': ['English', 'Malay', 'Mandarin Chinese', 'Tamil'], // Singapore
  'SK': ['Slovak'], // Slovakia
  'SI': ['Slovene'], // Slovenia
  'SB': ['English'], // Solomon Islands
  'SO': ['Somali', 'Arabic'], // Somalia
  'ZA': ['Afrikaans', 'English', 'Ndebele', 'Northern Sotho', 'Sotho', 'Swati', 'Tsonga', 'Tswana', 'Xhosa', 'Zulu'], // South Africa
  'SS': ['English'], // South Sudan
  'ES': ['Spanish'], // Spain
  'LK': ['Sinhala', 'Tamil'], // Sri Lanka
  'SD': ['Arabic', 'English'], // Sudan
  'SR': ['Dutch'], // Suriname
  'SE': ['Swedish'], // Sweden
  'CH': ['German', 'French', 'Italian', 'Romansh'], // Switzerland
  'SY': ['Arabic'], // Syrian Arab Republic
  'TJ': ['Tajik'], // Tajikistan
  'TZ': ['Swahili', 'English'], // Tanzania (United Republic of)
  'TH': ['Thai'], // Thailand
  'TL': ['Portuguese'], // Timor-Leste
  'TG': ['French'], // Togo
  'TO': ['English'], // Tonga
  'TT': ['English'], // Trinidad and Tobago
  'TN': ['Arabic'], // Tunisia
  'TR': ['Turkish'], // Turkey
  'TM': ['Russian'], // Turkmenistan
  'TV': ['English'], // Tuvalu
  'UG': ['English', 'Swahili'], // Uganda
  'UA': ['Ukrainian'], // Ukraine
  'AE': ['Arabic'], // United Arab Emirates
  'GB': ['English'], // United Kingdom of Great Britain and Northern Ireland
  'US': ['English', 'Spanish'], // United States of America
  'UY': ['Spanish'], // Uruguay
  'UZ': ['Uzbek'], // Uzbekistan
  'VU': ['English', 'French'], // Vanuatu
  'VE': ['Spanish'], // Venezuela (Bolivarian Republic of)
  'VN': ['Vietnamese'], // Viet Nam
  'YE': ['Arabic'], // Yemen
  'ZM': ['English'], // Zambia
  'ZW': ['English'], // Zimbabwe
};
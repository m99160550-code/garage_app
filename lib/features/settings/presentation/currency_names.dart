/// Currency names for the region's currencies and the expatriate ones in
/// the country list: (English, Arabic). Others show their code only.
const _names = <String, (String, String)>{
  'SAR': ('Saudi Riyal', 'ريال سعودي'),
  'AED': ('UAE Dirham', 'درهم إماراتي'),
  'KWD': ('Kuwaiti Dinar', 'دينار كويتي'),
  'QAR': ('Qatari Riyal', 'ريال قطري'),
  'BHD': ('Bahraini Dinar', 'دينار بحريني'),
  'OMR': ('Omani Rial', 'ريال عماني'),
  'EGP': ('Egyptian Pound', 'جنيه مصري'),
  'JOD': ('Jordanian Dinar', 'دينار أردني'),
  'LBP': ('Lebanese Pound', 'ليرة لبنانية'),
  'IQD': ('Iraqi Dinar', 'دينار عراقي'),
  'MAD': ('Moroccan Dirham', 'درهم مغربي'),
  'TND': ('Tunisian Dinar', 'دينار تونسي'),
  'DZD': ('Algerian Dinar', 'دينار جزائري'),
  'USD': ('US Dollar', 'دولار أمريكي'),
  'EUR': ('Euro', 'يورو'),
  'GBP': ('British Pound', 'جنيه إسترليني'),
  'CAD': ('Canadian Dollar', 'دولار كندي'),
  'INR': ('Indian Rupee', 'روبية هندية'),
  'PKR': ('Pakistani Rupee', 'روبية باكستانية'),
  'PHP': ('Philippine Peso', 'بيزو فلبيني'),
  'AUD': ('Australian Dollar', 'دولار أسترالي'),
  'CHF': ('Swiss Franc', 'فرنك سويسري'),
  'NOK': ('Norwegian Krone', 'كرونة نرويجية'),
  'SEK': ('Swedish Krona', 'كرونة سويدية'),
  'TRY': ('Turkish Lira', 'ليرة تركية'),
};

/// "Saudi Riyal", or `null` when unknown.
String? currencyName(String code, String languageCode) => switch (_names[code]) {
  (final en, final ar) => languageCode == 'ar' ? ar : en,
  null => null,
};

/// "SAR · Saudi Riyal" (spec S-24 item 4).
String currencyLabel(String code, String languageCode) {
  final name = currencyName(code, languageCode);
  return name == null ? code : '$code · $name';
}

/// Every currency with a name here, by code.
Iterable<String> get namedCurrencyCodes => _names.keys;

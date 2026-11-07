/// Currencies for the "how much did you pay" questions: the ISO 4217 code of each country's
/// currency, and the list the drop-down offers (codes are understood in every language).
library;

const _euro = {
  'AT', 'BE', 'HR', 'CY', 'EE', 'FI', 'FR', 'DE', 'GR', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PT', 'SK', 'SI', 'ES', //
  'AD', 'MC', 'SM', 'VA', 'ME', 'XK', 'GP', 'MQ', 'GF', 'RE', 'YT', 'PM', 'BL', 'MF', 'AX',
};

const _byCountry = {
  'RO': 'RON', 'HU': 'HUF', 'MD': 'MDL', 'UA': 'UAH', 'RS': 'RSD', 'BG': 'BGN', 'PL': 'PLN', 'CZ': 'CZK', 'GB': 'GBP',
  'CH': 'CHF', 'LI': 'CHF', 'NO': 'NOK', 'SE': 'SEK', 'DK': 'DKK', 'IS': 'ISK', 'BA': 'BAM', 'MK': 'MKD', 'AL': 'ALL',
  'TR': 'TRY', 'RU': 'RUB', 'BY': 'BYN', 'GE': 'GEL', 'AM': 'AMD', 'AZ': 'AZN', 'KZ': 'KZT', 'UZ': 'UZS', 'KG': 'KGS',
  'TJ': 'TJS', 'TM': 'TMT', 'US': 'USD', 'CA': 'CAD', 'MX': 'MXN', 'BR': 'BRL', 'AR': 'ARS', 'CL': 'CLP', 'CO': 'COP',
  'PE': 'PEN', 'UY': 'UYU', 'PY': 'PYG', 'BO': 'BOB', 'VE': 'VES', 'EC': 'USD', 'PA': 'PAB', 'CR': 'CRC', 'GT': 'GTQ',
  'HN': 'HNL', 'NI': 'NIO', 'SV': 'USD', 'DO': 'DOP', 'CU': 'CUP', 'JM': 'JMD', 'HT': 'HTG', 'TT': 'TTD', 'BS': 'BSD',
  'BB': 'BBD', 'BZ': 'BZD', 'PR': 'USD', 'CN': 'CNY', 'JP': 'JPY', 'KR': 'KRW', 'IN': 'INR', 'PK': 'PKR', 'BD': 'BDT',
  'LK': 'LKR', 'NP': 'NPR', 'ID': 'IDR', 'MY': 'MYR', 'SG': 'SGD', 'TH': 'THB', 'VN': 'VND', 'PH': 'PHP', 'MM': 'MMK',
  'KH': 'KHR', 'LA': 'LAK', 'MN': 'MNT', 'TW': 'TWD', 'HK': 'HKD', 'AU': 'AUD', 'NZ': 'NZD', 'FJ': 'FJD', 'PG': 'PGK',
  'SA': 'SAR', 'AE': 'AED', 'QA': 'QAR', 'KW': 'KWD', 'BH': 'BHD', 'OM': 'OMR', 'JO': 'JOD', 'IL': 'ILS', 'PS': 'ILS',
  'LB': 'LBP', 'SY': 'SYP', 'IQ': 'IQD', 'IR': 'IRR', 'AF': 'AFN', 'YE': 'YER', 'EG': 'EGP', 'MA': 'MAD', 'DZ': 'DZD',
  'TN': 'TND', 'LY': 'LYD', 'SD': 'SDG', 'ET': 'ETB', 'KE': 'KES', 'UG': 'UGX', 'TZ': 'TZS', 'RW': 'RWF', 'NG': 'NGN',
  'GH': 'GHS', 'ZA': 'ZAR', 'NA': 'NAD', 'BW': 'BWP', 'ZM': 'ZMW', 'ZW': 'USD', 'MZ': 'MZN', 'AO': 'AOA', 'CD': 'CDF',
  'MG': 'MGA', 'MW': 'MWK', 'SN': 'XOF', 'CI': 'XOF', 'ML': 'XOF', 'BF': 'XOF', 'NE': 'XOF', 'TG': 'XOF', 'BJ': 'XOF',
  'GW': 'XOF', 'CM': 'XAF', 'GA': 'XAF', 'CG': 'XAF', 'TD': 'XAF', 'CF': 'XAF', 'GQ': 'XAF', 'SL': 'SLE', 'LR': 'LRD',
  'GN': 'GNF', 'GM': 'GMD', 'MR': 'MRU', 'SO': 'SOS', 'DJ': 'DJF', 'ER': 'ERN', 'SS': 'SSP', 'BI': 'BIF', 'LS': 'LSL',
  'SZ': 'SZL', 'MU': 'MUR', 'SC': 'SCR', 'CV': 'CVE', 'MV': 'MVR', 'BT': 'BTN', 'BN': 'BND', 'TL': 'USD',
};

/// The currency of [countryCode] (ISO 3166-1 alpha-2), or euro when unknown.
String currencyOf(String? countryCode) {
  final c = countryCode?.toUpperCase();
  if (c == null) return 'EUR';
  if (_euro.contains(c)) return 'EUR';
  return _byCountry[c] ?? 'EUR';
}

/// Every currency in use in the world (ISO 4217, without funds and precious metals).
const _world = [
  'AED', 'AFN', 'ALL', 'AMD', 'ANG', 'AOA', 'ARS', 'AUD', 'AWG', 'AZN', 'BAM', 'BBD', 'BDT', 'BGN',
  'BHD', 'BIF', 'BMD', 'BND', 'BOB', 'BRL', 'BSD', 'BTN', 'BWP', 'BYN', 'BZD', 'CAD', 'CDF', 'CHF',
  'CLP', 'CNY', 'COP', 'CRC', 'CUP', 'CVE', 'CZK', 'DJF', 'DKK', 'DOP', 'DZD', 'EGP', 'ERN', 'ETB',
  'EUR', 'FJD', 'FKP', 'GBP', 'GEL', 'GHS', 'GIP', 'GMD', 'GNF', 'GTQ', 'GYD', 'HKD', 'HNL', 'HTG',
  'HUF', 'IDR', 'ILS', 'INR', 'IQD', 'IRR', 'ISK', 'JMD', 'JOD', 'JPY', 'KES', 'KGS', 'KHR', 'KMF',
  'KPW', 'KRW', 'KWD', 'KYD', 'KZT', 'LAK', 'LBP', 'LKR', 'LRD', 'LSL', 'LYD', 'MAD', 'MDL', 'MGA',
  'MKD', 'MMK', 'MNT', 'MOP', 'MRU', 'MUR', 'MVR', 'MWK', 'MXN', 'MYR', 'MZN', 'NAD', 'NGN', 'NIO',
  'NOK', 'NPR', 'NZD', 'OMR', 'PAB', 'PEN', 'PGK', 'PHP', 'PKR', 'PLN', 'PYG', 'QAR', 'RON', 'RSD',
  'RUB', 'RWF', 'SAR', 'SBD', 'SCR', 'SDG', 'SEK', 'SGD', 'SHP', 'SLE', 'SOS', 'SRD', 'SSP', 'STN',
  'SVC', 'SYP', 'SZL', 'THB', 'TJS', 'TMT', 'TND', 'TOP', 'TRY', 'TTD', 'TWD', 'TZS', 'UAH', 'UGX',
  'USD', 'UYU', 'UZS', 'VES', 'VND', 'VUV', 'WST', 'XAF', 'XCD', 'XCG', 'XOF', 'XPF', 'YER', 'ZAR',
  'ZMW', 'ZWG',
];

/// Every currency the drop-down offers: euro and the regional ones first, then all the
/// others in alphabetical order.
final List<String> allCurrencies = () {
  const first = ['EUR', 'RON', 'HUF', 'USD', 'GBP', 'CHF', 'PLN', 'CZK', 'BGN', 'MDL', 'UAH', 'RSD'];
  final rest = {..._world, ..._byCountry.values}.difference(first.toSet()).toList()..sort();
  return [...first, ...rest];
}();

/// The usual sign of each currency ($, €, lei), where it has one.
const _symbols = {'EUR': '€', 'USD': '\$', 'GBP': '£', 'RON': 'lei', 'HUF': 'Ft', 'CHF': 'Fr.', 'PLN': 'zł', 'CZK': 'Kč', 'BGN': 'лв', 'MDL': 'L', 'UAH': '₴', 'RSD': 'дин.', 'JPY': '¥', 'CNY': '¥', 'INR': '₹', 'RUB': '₽', 'TRY': '₺', 'KRW': '₩', 'ILS': '₪', 'NGN': '₦', 'PHP': '₱', 'VND': '₫', 'THB': '฿', 'BRL': 'R\$', 'ZAR': 'R', 'AUD': 'A\$', 'CAD': 'C\$', 'NZD': 'NZ\$', 'HKD': 'HK\$', 'SGD': 'S\$', 'MXN': 'Mex\$', 'SEK': 'kr', 'NOK': 'kr', 'DKK': 'kr', 'ISK': 'kr', 'GEL': '₾', 'AZN': '₼', 'KZT': '₸', 'AMD': '֏', 'BDT': '৳', 'PKR': '₨', 'LKR': 'Rs', 'NPR': 'रु', 'IDR': 'Rp', 'MYR': 'RM', 'TWD': 'NT\$', 'EGP': 'E£', 'SAR': 'SR', 'AED': 'د.إ', 'QAR': 'QR', 'KWD': 'KD', 'BHD': 'BD', 'OMR': 'ر.ع.', 'MAD': 'DH', 'KES': 'KSh', 'UGX': 'USh', 'TZS': 'TSh', 'GHS': '₵', 'XOF': 'CFA', 'XAF': 'FCFA', 'ARS': '\$', 'CLP': '\$', 'COP': '\$', 'MNT': '₮', 'LAK': '₭', 'KHR': '៛', 'PYG': '₲', 'CRC': '₡', 'UZS': 'soʻm', 'BYN': 'Br', 'ALL': 'L', 'MKD': 'ден', 'BAM': 'KM', 'XCD': 'EC\$', 'JMD': 'J\$', 'TTD': 'TT\$', 'BBD': 'Bds\$', 'BSD': 'B\$', 'BZD': 'BZ\$', 'GYD': 'G\$', 'PEN': 'S/', 'BOB': 'Bs', 'VES': 'Bs.', 'GTQ': 'Q', 'HNL': 'L', 'NIO': 'C\$', 'DOP': 'RD\$', 'PAB': 'B/.', 'UYU': '\$U', 'ZMW': 'K', 'MWK': 'MK', 'BWP': 'P', 'NAD': 'N\$', 'MUR': '₨', 'SCR': '₨', 'ETB': 'Br', 'RWF': 'FRw', 'SOS': 'Sh', 'TND': 'DT', 'DZD': 'DA', 'LYD': 'LD', 'IQD': 'ع.د', 'IRR': '﷼', 'AFN': '؋', 'JOD': 'JD', 'LBP': 'L£', 'SYP': 'LS', 'YER': '﷼', 'MVR': 'Rf', 'BTN': 'Nu.', 'MMK': 'K', 'MOP': 'MOP\$', 'FJD': 'FJ\$', 'PGK': 'K', 'WST': 'WS\$', 'TOP': 'T\$', 'SBD': 'SI\$', 'VUV': 'VT', 'XPF': '₣', 'TJS': 'SM', 'TMT': 'm', 'KGS': 'сом', 'KPW': '₩', 'CUP': '\$', 'SRD': '\$', 'KYD': 'CI\$', 'BMD': 'BD\$', 'AWG': 'ƒ', 'ANG': 'ƒ', 'XCG': 'Cg', 'FKP': '£', 'GIP': '£', 'SHP': '£', 'LRD': 'L\$', 'SLE': 'Le', 'GMD': 'D', 'GNF': 'FG', 'CDF': 'FC', 'AOA': 'Kz', 'MZN': 'MT', 'MGA': 'Ar', 'LSL': 'L', 'SZL': 'E', 'KMF': 'CF', 'DJF': 'Fdj', 'ERN': 'Nfk', 'SDG': '£SD', 'SSP': 'SS£', 'BIF': 'FBu', 'STN': 'Db', 'CVE': 'Esc', 'MRU': 'UM', 'ZWG': 'ZiG', 'HTG': 'G', 'BND': 'B\$', 'SVC': '₡'};

/// "USD ($)", or just the code when the currency has no sign of its own.
String currencyLabel(String code) {
  final s = _symbols[code];
  return s == null || s == code ? code : '$code ($s)';
}

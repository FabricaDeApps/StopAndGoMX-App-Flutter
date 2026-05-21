import 'package:intl/intl.dart';

final NumberFormat _mxnFormatter = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 2,
);

final NumberFormat _usdFormatter = NumberFormat.currency(
  locale: 'en_US',
  symbol: 'USD ',
  decimalDigits: 2,
);

String formatEcommercePrice({
  required String currency,
  required double amount,
}) {
  final normalizedCurrency = currency.trim().toUpperCase();
  if (normalizedCurrency == 'USD') {
    return _usdFormatter.format(amount);
  }
  return _mxnFormatter.format(amount);
}

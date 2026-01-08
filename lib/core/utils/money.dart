// core/utils/money.dart
import 'package:intl/intl.dart';

final moneyFormatter = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 2,
);

String money(double v) => moneyFormatter.format(v);

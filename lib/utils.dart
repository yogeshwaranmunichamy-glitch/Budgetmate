import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

/// Formats a number as Indian Rupees with lakh/crore grouping, e.g. ₹1,00,000.
String fmtInr(num value) => _inr.format(value);

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);

String newId() => 't${DateTime.now().microsecondsSinceEpoch}';

import 'package:intl/intl.dart';

class CurrencyFormatter {
  static double roundAmount(double amount) {
    return (amount * 100.0).roundToDouble() / 100.0;
  }

  static String format(double amount, String currencyCode) {
    final format = NumberFormat.currency(
      symbol: _getSymbol(currencyCode),
      decimalDigits: 2,
    );
    return format.format(roundAmount(amount));
  }

  static String _getSymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      default:
        return '$currencyCode ';
    }
  }
}

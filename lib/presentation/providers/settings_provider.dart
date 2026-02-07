import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  Locale _locale = const Locale('tr'); // Default TR as requested
  String _currency = 'TRY'; // Default TRY as requested
  String _currencySymbol = '₺';
  double _exchangeRate = 34.50;

  Locale get locale => _locale;
  String get currency => _currency;

  // Required by DashboardPage
  String get currencySymbol => _currencySymbol;
  double get exchangeRate => _exchangeRate;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void setCurrency(String currency) {
    _currency = currency;

    // Update dependent values
    switch (currency) {
      case 'TRY':
        _currencySymbol = '₺';
        _exchangeRate = 34.50;
        break;
      case 'EUR':
        _currencySymbol = '€';
        _exchangeRate = 0.92;
        break;
      case 'GBP':
        _currencySymbol = '£';
        _exchangeRate = 0.79;
        break;
      case 'JPY':
        _currencySymbol = '¥';
        _exchangeRate = 148.0;
        break;
      case 'USD':
      default:
        _currencySymbol = '\$';
        _exchangeRate = 1.0;
        break;
    }

    notifyListeners();
  }

  // Theme Logic
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

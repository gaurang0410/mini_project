// lib/data/currency_list.dart
import '../models/currency.dart';

// Short list for non-VIP users
final List<Currency> freeCurrencies = [
  Currency(code: "USD", name: "United States Dollar"),
  Currency(code: "EUR", name: "Euro"),
  Currency(code: "JPY", name: "Japanese Yen"),
  Currency(code: "GBP", name: "British Pound Sterling"),
  Currency(code: "INR", name: "Indian Rupee"),
  Currency(code: "AUD", name: "Australian Dollar"),
  Currency(code: "CAD", name: "Canadian Dollar"),
];

// Full list for VIP users (remains the same as before)
final List<Currency> allCurrencies = [
  Currency(code: "USD", name: "United States Dollar"),
  Currency(code: "EUR", name: "Euro"),
  Currency(code: "JPY", name: "Japanese Yen"),
  Currency(code: "GBP", name: "British Pound Sterling"),
  // ... (include ALL 150+ currencies here) ...
   Currency(code: "INR", name: "Indian Rupee"),
   Currency(code: "AUD", name: "Australian Dollar"),
   Currency(code: "CAD", name: "Canadian Dollar"),
   // ... rest of the list ...
   Currency(code: "ZWL", name: "Zimbabwean Dollar"),
];
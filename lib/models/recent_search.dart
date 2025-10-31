// lib/models/recent_search.dart
import 'currency.dart';

class RecentSearch {
  final int? id;
  final Currency fromCurrency;
  final Currency toCurrency;

  RecentSearch({
    this.id,
    required this.fromCurrency,
    required this.toCurrency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromCode': fromCurrency.code,
      'fromName': fromCurrency.name,
      'toCode': toCurrency.code,
      'toName': toCurrency.name,
    };
  }
}
// lib/services/api_service.dart
import 'dart:convert'; // <-- FIX: Was 'dart.convert'
import 'package:http/http.dart' as http;

class ApiService {
  
  final String _apiKey = "29735bda8db8aa82b00c1bf2"; 
  final String _baseUrl = "https://v6.exchangerate-api.com/v6/";

  Future<double> getConversionRate(String from, String to) async {
    print("--- [API] Attempting to get conversion rate for $from to $to");
    final url = Uri.parse('$_baseUrl$_apiKey/pair/$from/$to');
    print("--- [API] Calling URL: $url");

    try {
      final response = await http.get(url);

      print("--- [API] Response Status Code: ${response.statusCode}");
      // print("API Response Body: ${response.body}"); // Uncomment for deep debugging

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // <-- This now works
        if (data['result'] == 'error') {
          print("--- [API] API returned a known error: ${data['error-type']}");
          throw Exception('API error: ${data['error-type']}');
        }
        print("--- [API] Successfully fetched rate: ${data['conversion_rate']}");
        return data['conversion_rate'].toDouble();
      } else {
        print("--- [API] API call failed with status code ${response.statusCode}");
        throw Exception('Server error');
      }
    } catch (e) {
      print("--- [API] An unexpected error occurred: $e");
      throw Exception('Network or parsing error');
    }
  }
}
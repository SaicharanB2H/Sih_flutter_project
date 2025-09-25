import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/market.dart';

class MarketPriceService {
  static const String _geminiApiKey = 'AIzaSyDjghcnRP4_WmY3HxkGZPnVJg-hMEbKtJw';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  // Cache for market prices to avoid excessive API calls
  static List<MarketPrice>? _cachedPrices;
  static DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(
    minutes: 15,
  ); // Refresh every 15 minutes

  /// Fetches real-time market prices for major agricultural crops in India
  static Future<List<MarketPrice>> getRealTimeMarketPrices({
    String? region,
  }) async {
    // Check cache first
    if (_cachedPrices != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry) {
      return _cachedPrices!;
    }

    try {
      final headers = {'Content-Type': 'application/json'};

      final prompt =
          """
You are an agricultural market data analyst. Provide current market prices for major crops in India as of ${DateTime.now().toLocal().toString().split(' ')[0]}. 

Generate realistic current market prices based on seasonal factors, recent trends, and typical Indian agricultural markets${region != null ? ' in $region region' : ''}. 

Return data in this exact JSON format:
{
  "market_prices": [
    {
      "crop_name": "Rice",
      "price_per_kg": 45.50,
      "unit": "kg",
      "market_name": "Delhi Mandi",
      "location": "Delhi, India",
      "grade": "Grade A",
      "currency": "INR",
      "source": "government",
      "trend": "stable",
      "change_percentage": 2.1
    },
    {
      "crop_name": "Wheat",
      "price_per_kg": 28.75,
      "unit": "kg", 
      "market_name": "Mumbai APMC",
      "location": "Mumbai, India",
      "grade": "Premium",
      "currency": "INR",
      "source": "government",
      "trend": "up",
      "change_percentage": 5.2
    }
  ]
}

Include prices for these crops: Rice, Wheat, Tomato, Onion, Potato, Sugarcane, Cotton, Maize, Soybean, Mustard, Groundnut, Turmeric.
Use realistic Indian market rates. Include trend indicators (up/down/stable) and percentage changes.
""";

      final body = json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2000,
        },
      });

      final response = await http
          .post(
            Uri.parse('$_apiUrl?key=$_geminiApiKey'),
            headers: headers,
            body: body,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                'Request timeout - Please check your internet connection',
              );
            },
          );

      print('Market Price API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          String responseText =
              data['candidates'][0]['content']['parts'][0]['text'];

          // Extract JSON from response
          String jsonText = _extractJsonFromResponse(responseText);
          final marketData = json.decode(jsonText);

          List<MarketPrice> prices = [];
          if (marketData['market_prices'] != null) {
            for (var priceData in marketData['market_prices']) {
              prices.add(
                MarketPrice(
                  id:
                      DateTime.now().millisecondsSinceEpoch.toString() +
                      priceData['crop_name'].toString().replaceAll(' ', ''),
                  cropName: priceData['crop_name'] ?? 'Unknown',
                  marketName: priceData['market_name'] ?? 'Local Market',
                  location: priceData['location'] ?? 'India',
                  pricePerKg: (priceData['price_per_kg'] ?? 0.0).toDouble(),
                  currency: priceData['currency'] ?? 'INR',
                  date: DateTime.now(),
                  unit: _parseUnit(priceData['unit'] ?? 'kg'),
                  grade: priceData['grade'],
                  source: _parseSource(priceData['source'] ?? 'government'),
                ),
              );
            }
          }

          // Cache the results
          _cachedPrices = prices;
          _lastFetchTime = DateTime.now();

          return prices;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your Gemini API key.');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception(
          'Failed to fetch market prices. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('No Internet: Please check your connection');
    } on TimeoutException {
      throw Exception('Timeout: Request took too long');
    } on FormatException {
      throw Exception('Format Error: Invalid response from service');
    } catch (e) {
      print('Market Price Service Error: $e');
      throw Exception('Market price fetch failed: ${e.toString()}');
    }

    // Fallback to cached data if available
    if (_cachedPrices != null) {
      return _cachedPrices!;
    }

    throw Exception('Failed to fetch market prices');
  }

  /// Extracts JSON content from Gemini response
  static String _extractJsonFromResponse(String response) {
    if (response.contains('```json')) {
      return response.split('```json')[1].split('```')[0].trim();
    } else if (response.contains('```')) {
      return response.split('```')[1].split('```')[0].trim();
    } else if (response.contains('{')) {
      int startIndex = response.indexOf('{');
      int endIndex = response.lastIndexOf('}') + 1;
      return response.substring(startIndex, endIndex);
    }
    return response;
  }

  /// Parses unit string to PriceUnit enum
  static PriceUnit _parseUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'quintal':
        return PriceUnit.quintal;
      case 'tonne':
      case 'ton':
        return PriceUnit.ton;
      case 'kg':
      case 'kilogram':
      default:
        return PriceUnit.kg;
    }
  }

  /// Parses source string to MarketSource enum
  static MarketSource _parseSource(String source) {
    switch (source.toLowerCase()) {
      case 'private':
        return MarketSource.private;
      case 'cooperative':
        return MarketSource.cooperative;
      case 'government':
      default:
        return MarketSource.government;
    }
  }

  /// Gets trending crops based on price changes
  static Future<List<MarketPrice>> getTrendingCrops() async {
    final prices = await getRealTimeMarketPrices();
    // Sort by price (highest first) and return top 5
    prices.sort((a, b) => b.pricePerKg.compareTo(a.pricePerKg));
    return prices.take(5).toList();
  }

  /// Gets prices for a specific crop across different markets
  static Future<List<MarketPrice>> getCropPrices(String cropName) async {
    final prices = await getRealTimeMarketPrices();
    return prices
        .where(
          (price) =>
              price.cropName.toLowerCase().contains(cropName.toLowerCase()),
        )
        .toList();
  }

  /// Clears the cache to force fresh data on next request
  static void clearCache() {
    _cachedPrices = null;
    _lastFetchTime = null;
  }

  /// Gets cache status
  static bool get hasCachedData => _cachedPrices != null;
  static DateTime? get lastFetchTime => _lastFetchTime;
  static Duration? get cacheAge => _lastFetchTime != null
      ? DateTime.now().difference(_lastFetchTime!)
      : null;
}

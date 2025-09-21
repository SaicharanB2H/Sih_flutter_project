import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/theme/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isLoading = true; // Start with loading state
  Position? _currentPosition;
  String _currentLocation = 'Loading weather...';
  WeatherData? _currentWeather;
  List<WeatherForecast> _forecast = [];
  List<WeatherAlert> _alerts = [];

  // OpenWeatherMap API key
  final String _weatherApiKey =
      'a81c6e422c4b47a3db18efbd8579886f'; // Your OpenWeather API key

  @override
  void initState() {
    super.initState();
    print('Weather screen initialized');
    // Test the API first, then try location-based weather
    _testWeatherAPI();
    // _getCurrentLocationAndWeather();
  }

  Future<void> _testWeatherAPI() async {
    print('Testing weather API with fixed coordinates...');
    try {
      // Test with New Delhi coordinates
      final testLat = 28.6139;
      final testLon = 77.2090;

      final currentWeatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$testLat&lon=$testLon&appid=$_weatherApiKey&units=metric';

      print('Test Weather API URL: $currentWeatherUrl');

      final currentResponse = await http.get(Uri.parse(currentWeatherUrl));

      print('Test Weather API Response status: ${currentResponse.statusCode}');
      print('Test Weather API Response body: ${currentResponse.body}');

      if (currentResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);
        setState(() {
          _currentWeather = WeatherData(
            location: 'New Delhi (Test)',
            temperature: currentData['main']['temp'].round(),
            condition: currentData['weather'][0]['description'],
            humidity: currentData['main']['humidity'],
            windSpeed: (currentData['wind']['speed'] * 3.6).round(),
            uvIndex: 0,
            icon: _getWeatherIcon(currentData['weather'][0]['main']),
          );
          _isLoading = false;
        });
        print('Test weather data loaded successfully');
      } else {
        print('Test Weather API error: ${currentResponse.statusCode}');
        setState(() {
          _currentLocation = 'Weather API Error: ${currentResponse.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Test Weather API exception: $e');
      setState(() {
        _currentLocation = 'Weather API Exception: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocationAndWeather() async {
    print('Starting weather fetch process...');
    setState(() {
      _isLoading = true;
    });

    try {
      print('Checking location permission...');
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('Current permission: $permission');

      if (permission == LocationPermission.denied) {
        print('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          print('Location permission denied by user');
          setState(() {
            _currentLocation = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        setState(() {
          _currentLocation = 'Location permissions are permanently denied';
          _isLoading = false;
        });
        return;
      }

      print('Getting current position...');
      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      print(
        'Got position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocation = '${place.locality}, ${place.administrativeArea}';
        });
        print('Location set to: $_currentLocation');
      }

      // Fetch weather data
      await _fetchWeatherData();
    } catch (e) {
      print('Error in _getCurrentLocationAndWeather: $e');
      setState(() {
        _currentLocation = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    if (_currentPosition == null) return;

    print(
      'Fetching weather data for lat: ${_currentPosition!.latitude}, lon: ${_currentPosition!.longitude}',
    );

    try {
      // Fetch current weather
      final currentWeatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=${_currentPosition!.latitude}&lon=${_currentPosition!.longitude}&appid=$_weatherApiKey&units=metric';

      print('Weather API URL: $currentWeatherUrl');

      final currentResponse = await http.get(Uri.parse(currentWeatherUrl));

      print('Weather API Response status: ${currentResponse.statusCode}');
      print('Weather API Response body: ${currentResponse.body}');

      if (currentResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);
        setState(() {
          _currentWeather = WeatherData(
            location: _currentLocation,
            temperature: currentData['main']['temp'].round(),
            condition: currentData['weather'][0]['description'],
            humidity: currentData['main']['humidity'],
            windSpeed: (currentData['wind']['speed'] * 3.6)
                .round(), // Convert m/s to km/h
            uvIndex: 0, // UV data requires separate API call
            icon: _getWeatherIcon(currentData['weather'][0]['main']),
          );
        });
        print('Weather data loaded successfully');
      } else {
        print('Weather API error: ${currentResponse.statusCode}');
      }

      // Fetch 5-day forecast
      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=${_currentPosition!.latitude}&lon=${_currentPosition!.longitude}&appid=$_weatherApiKey&units=metric';

      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (forecastResponse.statusCode == 200) {
        final forecastData = json.decode(forecastResponse.body);
        _processForecastData(forecastData);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Weather fetch completed with error: $e');
    }
  }

  void _processForecastData(Map<String, dynamic> data) {
    List<WeatherForecast> forecasts = [];
    Map<String, Map<String, dynamic>> dailyData = {};

    for (var item in data['list']) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      String dateKey = '${date.year}-${date.month}-${date.day}';

      if (!dailyData.containsKey(dateKey)) {
        dailyData[dateKey] = {
          'date': date,
          'temps': <double>[],
          'conditions': <String>[],
          'icons': <String>[],
        };
      }

      dailyData[dateKey]!['temps'].add(item['main']['temp'].toDouble());
      dailyData[dateKey]!['conditions'].add(item['weather'][0]['main']);
      dailyData[dateKey]!['icons'].add(item['weather'][0]['main']);
    }

    List<String> days = ['Today', 'Tomorrow', 'Day 3', 'Day 4', 'Day 5'];
    int dayIndex = 0;

    for (var entry in dailyData.entries.take(5)) {
      var dayData = entry.value;
      List<double> temps = dayData['temps'];
      List<String> conditions = dayData['conditions'];

      forecasts.add(
        WeatherForecast(
          day: dayIndex < days.length ? days[dayIndex] : 'Day ${dayIndex + 1}',
          icon: _getWeatherIcon(
            conditions.isNotEmpty ? conditions[0] : 'Clear',
          ),
          high: temps.isNotEmpty
              ? temps.reduce((a, b) => a > b ? a : b).round()
              : 0,
          low: temps.isNotEmpty
              ? temps.reduce((a, b) => a < b ? a : b).round()
              : 0,
          condition: conditions.isNotEmpty ? conditions[0] : 'Clear',
        ),
      );
      dayIndex++;
    }

    setState(() {
      _forecast = forecasts;
      _generateWeatherAlerts();
    });
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.wb_cloudy;
      case 'rain':
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.cloud;
      default:
        return Icons.wb_sunny;
    }
  }

  void _generateWeatherAlerts() {
    List<WeatherAlert> alerts = [];

    if (_currentWeather != null) {
      // High humidity alert
      if (_currentWeather!.humidity > 80) {
        alerts.add(
          WeatherAlert(
            title: 'High Humidity Alert',
            message:
                'Humidity is ${_currentWeather!.humidity}%. Monitor crops for fungal diseases.',
            severity: AlertSeverity.warning,
            icon: Icons.water_drop,
          ),
        );
      }

      // Strong wind alert
      if (_currentWeather!.windSpeed > 30) {
        alerts.add(
          WeatherAlert(
            title: 'Strong Wind Warning',
            message:
                'Wind speed is ${_currentWeather!.windSpeed} km/h. Secure loose items and consider delaying spraying.',
            severity: AlertSeverity.warning,
            icon: Icons.air,
          ),
        );
      }
    }

    // Check forecast for rain
    bool rainExpected = _forecast.any(
      (f) => f.condition.toLowerCase().contains('rain'),
    );
    if (rainExpected) {
      alerts.add(
        WeatherAlert(
          title: 'Rain Expected',
          message:
              'Rain is forecasted. Plan irrigation accordingly and protect sensitive crops.',
          severity: AlertSeverity.warning,
          icon: Icons.umbrella,
        ),
      );
    }

    setState(() {
      _alerts = alerts;
    });
  }

  Future<void> _refreshWeather() async {
    await _getCurrentLocationAndWeather();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weather updated!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshWeather,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWeather,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Getting weather data...'),
                    ],
                  ),
                )
              : _currentWeather == null
              ? const Center(child: Text('Unable to load weather data'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Weather Card
                    Card(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.secondaryBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _currentWeather?.location ?? 'Unknown Location',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Icon(
                              _currentWeather?.icon ?? Icons.wb_sunny,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_currentWeather?.temperature ?? 0}°C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentWeather?.condition ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Weather Details
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Conditions',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildWeatherDetail(
                                    'Humidity',
                                    '${_currentWeather?.humidity ?? 0}%',
                                    Icons.water_drop,
                                  ),
                                ),
                                Expanded(
                                  child: _buildWeatherDetail(
                                    'Wind',
                                    '${_currentWeather?.windSpeed ?? 0} km/h',
                                    Icons.air,
                                  ),
                                ),
                                Expanded(
                                  child: _buildWeatherDetail(
                                    'UV Index',
                                    '${_currentWeather?.uvIndex ?? 0}',
                                    Icons.wb_sunny,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Weather Alerts
                    if (_alerts.isNotEmpty) ...[
                      Text(
                        'Weather Alerts',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._alerts.map(
                        (alert) => Card(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: alert.severity == AlertSeverity.warning
                                  ? AppTheme.warningOrange.withOpacity(0.1)
                                  : AppTheme.errorRed.withOpacity(0.1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  alert.icon,
                                  color: alert.severity == AlertSeverity.warning
                                      ? AppTheme.warningOrange
                                      : AppTheme.errorRed,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(alert.message),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 5-Day Forecast
                    Text(
                      '5-Day Forecast',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: _forecast
                            .map((forecast) => _buildForecastItem(forecast))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Farming Tips based on weather
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb,
                                  color: AppTheme.warningOrange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Farming Tips',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentWeather != null
                                  ? '• Current conditions: ${_currentWeather!.condition}'
                                  : '• Weather data loading...',
                            ),
                            Text(
                              _currentWeather != null
                                  ? '• Humidity: ${_currentWeather!.humidity}% - ${_currentWeather!.humidity > 70 ? 'Monitor for fungal diseases' : 'Good humidity levels'}'
                                  : '• Humidity information will appear here',
                            ),
                            Text(
                              _currentWeather != null
                                  ? '• Wind: ${_currentWeather!.windSpeed} km/h - ${_currentWeather!.windSpeed > 20 ? 'Avoid spraying pesticides' : 'Good for outdoor activities'}'
                                  : '• Wind information will appear here',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildForecastItem(WeatherForecast forecast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              forecast.day,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Icon(forecast.icon, color: AppTheme.primaryBlue),
          const SizedBox(width: 16),
          Expanded(child: Text(forecast.condition)),
          Text(
            '${forecast.high}°/${forecast.low}°',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class WeatherData {
  final String location;
  final int temperature;
  final String condition;
  final int humidity;
  final int windSpeed;
  final int uvIndex;
  final IconData icon;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.icon,
  });
}

class WeatherForecast {
  final String day;
  final IconData icon;
  final int high;
  final int low;
  final String condition;

  WeatherForecast({
    required this.day,
    required this.icon,
    required this.high,
    required this.low,
    required this.condition,
  });
}

class WeatherAlert {
  final String title;
  final String message;
  final AlertSeverity severity;
  final IconData icon;

  WeatherAlert({
    required this.title,
    required this.message,
    required this.severity,
    required this.icon,
  });
}

enum AlertSeverity { warning, severe }

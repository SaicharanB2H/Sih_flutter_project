import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/theme/app_theme.dart';

class SimpleWeatherScreen extends StatefulWidget {
  const SimpleWeatherScreen({super.key});

  @override
  State<SimpleWeatherScreen> createState() => _SimpleWeatherScreenState();
}

class _SimpleWeatherScreenState extends State<SimpleWeatherScreen> {
  bool _isLoading = true;
  String _status = 'Loading weather data...';
  String _temperature = '--';
  String _condition = '--';
  String _location = 'New Delhi';

  final String _weatherApiKey = 'a81c6e422c4b47a3db18efbd8579886f';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      setState(() {
        _status = 'Fetching weather...';
      });

      // Test with New Delhi coordinates
      final lat = 28.6139;
      final lon = 77.2090;

      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_weatherApiKey&units=metric';

      print('Weather API URL: $url');

      final response = await http.get(Uri.parse(url));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _temperature = '${data['main']['temp'].round()}°C';
          _condition = data['weather'][0]['description'];
          _location = data['name'] ?? 'New Delhi';
          _status = 'Weather loaded successfully!';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = 'API Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Weather Error: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(color: AppTheme.primaryGreen)
            else
              Column(
                children: [
                  const Icon(
                    Icons.wb_sunny,
                    size: 80,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _location,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _temperature,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _condition.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Info:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Status: $_status'),
                  const SizedBox(height: 4),
                  Text('API Key: ${_weatherApiKey.substring(0, 10)}...'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _status = 'Reloading...';
                });
                _fetchWeatherData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh Weather'),
            ),
          ],
        ),
      ),
    );
  }
}

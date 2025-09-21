import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import '../../shared/theme/app_theme.dart';

class WorkingWeatherScreen extends StatefulWidget {
  const WorkingWeatherScreen({super.key});

  @override
  State<WorkingWeatherScreen> createState() => _WorkingWeatherScreenState();
}

class _WorkingWeatherScreenState extends State<WorkingWeatherScreen> {
  bool _isLoading = true;
  String _status = 'Getting your location...';
  String _temperature = '--';
  String _condition = '--';
  String _location = 'Locating...';
  int _humidity = 0;
  int _windSpeed = 0;
  Position? _currentPosition;

  final String _weatherApiKey = 'a81c6e422c4b47a3db18efbd8579886f';

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndWeather();
  }

  Future<void> _getCurrentLocationAndWeather() async {
    print('WorkingWeatherScreen: Starting location and weather fetch...');

    try {
      setState(() {
        _isLoading = true;
        _status = 'Checking location permissions...';
      });

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('WorkingWeatherScreen: Current permission: $permission');

      if (permission == LocationPermission.denied) {
        setState(() {
          _status = 'Requesting location permission...';
        });
        permission = await Geolocator.requestPermission();
        print('WorkingWeatherScreen: Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          setState(() {
            _status = 'Location permission denied. Using default location.';
          });
          await _loadDefaultWeatherData();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _status =
              'Location permissions permanently denied. Using default location.';
        });
        await _loadDefaultWeatherData();
        return;
      }

      setState(() {
        _status = 'Getting your location...';
      });

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      print(
        'WorkingWeatherScreen: Got position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );

      // Get address from coordinates
      setState(() {
        _status = 'Getting location name...';
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String locationName =
            place.locality ?? place.subAdministrativeArea ?? 'Unknown';
        if (place.administrativeArea != null) {
          locationName += ', ${place.administrativeArea}';
        }

        setState(() {
          _location = locationName;
          _status = 'Loading weather data...';
        });
        print('WorkingWeatherScreen: Location set to: $locationName');
      }

      // Fetch weather data using actual coordinates
      await _loadWeatherDataForLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } catch (e) {
      print('WorkingWeatherScreen: Location error: $e');
      setState(() {
        _status = 'Location error. Using default location.';
      });
      await _loadDefaultWeatherData();
    }
  }

  Future<void> _loadDefaultWeatherData() async {
    print('WorkingWeatherScreen: Loading default weather data for Delhi...');
    setState(() {
      _location = 'New Delhi (Default)';
      _status = 'Loading default weather...';
    });
    await _loadWeatherDataForLocation(28.6139, 77.2090);
  }

  Future<void> _loadWeatherDataForLocation(double lat, double lon) async {
    print('WorkingWeatherScreen: Loading weather for lat: $lat, lon: $lon');

    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_weatherApiKey&units=metric';

      print('WorkingWeatherScreen: API URL: $url');

      final response = await http.get(Uri.parse(url));

      print('WorkingWeatherScreen: Response status: ${response.statusCode}');
      print('WorkingWeatherScreen: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _temperature = '${data['main']['temp'].round()}°C';
          _condition = data['weather'][0]['description'];
          if (_location == 'Locating...' || _location.isEmpty) {
            _location = data['name'] ?? 'Unknown Location';
          }
          _humidity = data['main']['humidity'];
          _windSpeed = (data['wind']['speed'] * 3.6)
              .round(); // Convert m/s to km/h
          _status = 'Weather loaded successfully!';
          _isLoading = false;
        });

        print('WorkingWeatherScreen: Weather data loaded successfully');
      } else {
        setState(() {
          _status = 'Weather API Error: HTTP ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('WorkingWeatherScreen: Weather API Error: $e');
      setState(() {
        _status = 'Weather Error: $e';
        _isLoading = false;
      });
    }
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
            onPressed: () {
              setState(() {
                _isLoading = true;
                _status = 'Refreshing...';
              });
              _getCurrentLocationAndWeather();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isLoading = true;
            _status = 'Refreshing...';
          });
          await _getCurrentLocationAndWeather();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status Card
              Card(
                color: _isLoading
                    ? Colors.blue.shade50
                    : (_status.contains('Error')
                          ? Colors.red.shade50
                          : Colors.green.shade50),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _status.contains('Error')
                              ? Icons.error
                              : Icons.check_circle,
                          color: _status.contains('Error')
                              ? Colors.red
                              : Colors.green,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _status.contains('Error')
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Weather Card
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _location,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Icon(
                        _getWeatherIcon(_condition),
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _temperature,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _condition,
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
                        'Weather Details',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'Humidity',
                              '$_humidity%',
                              Icons.water_drop,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              'Wind Speed',
                              '$_windSpeed km/h',
                              Icons.air,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Debug Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('API Key: ${_weatherApiKey.substring(0, 8)}...'),
                      Text('Location: Delhi (28.6139, 77.2090)'),
                      Text('Status: $_status'),
                      Text('Loading: $_isLoading'),
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

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}

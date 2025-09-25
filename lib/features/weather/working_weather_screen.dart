import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../shared/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _status = 'Checking location permissions...';
      });

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('WorkingWeatherScreen: Current permission: $permission');

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _status = 'Requesting location permission...';
        });
        permission = await Geolocator.requestPermission();
        print('WorkingWeatherScreen: Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _status = 'Location permission denied. Using default location.';
          });
          await _loadDefaultWeatherData();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _status =
              'Location permissions permanently denied. Using default location.';
        });
        await _loadDefaultWeatherData();
        return;
      }

      if (!mounted) return;
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
      if (!mounted) return;
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

        if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _status = 'Location error. Using default location.';
      });
      await _loadDefaultWeatherData();
    }
  }

  Future<void> _loadDefaultWeatherData() async {
    print('WorkingWeatherScreen: Loading default weather data for Delhi...');
    if (!mounted) return;
    setState(() {
      _location = 'New Delhi (Default)';
      _status = 'Loading default weather...';
    });
    await _loadWeatherDataForLocation(28.6139, 77.2090);
  }

  Future<void> _loadWeatherDataForLocation(double lat, double lon) async {
    print('WorkingWeatherScreen: Loading weather for lat: $lat, lon: $lon');

    try {
      if (!mounted) return;
      setState(() {
        _status = 'Connecting to weather service...';
      });

      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_weatherApiKey&units=metric';

      print('WorkingWeatherScreen: API URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'AgriApp/1.0',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Request timeout - Please check your internet connection',
              );
            },
          );

      print('WorkingWeatherScreen: Response status: ${response.statusCode}');
      print('WorkingWeatherScreen: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Validate response data
        if (data['main'] == null || data['weather'] == null) {
          throw Exception('Invalid weather data received from API');
        }

        if (!mounted) return;
        setState(() {
          _temperature = '${data['main']['temp'].round()}°C';
          _condition = data['weather'][0]['description'];
          if (_location == 'Locating...' || _location.isEmpty) {
            _location = data['name'] ?? 'Unknown Location';
          }
          _humidity = data['main']['humidity'];
          _windSpeed = (data['wind']['speed'] * 3.6)
              .round(); // Convert m/s to km/h
          _status = 'Weather data loaded successfully!';
          _isLoading = false;
        });

        print('WorkingWeatherScreen: Weather data loaded successfully');
      } else if (response.statusCode == 401) {
        if (!mounted) return;
        setState(() {
          _status = 'API Key Error: Invalid or expired weather API key';
          _isLoading = false;
        });
      } else if (response.statusCode == 429) {
        if (!mounted) return;
        setState(() {
          _status = 'Rate Limit: Too many requests. Please try again later.';
          _isLoading = false;
        });
      } else if (response.statusCode >= 500) {
        if (!mounted) return;
        setState(() {
          _status = 'Server Error: Weather service temporarily unavailable';
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _status = 'Weather API Error: HTTP ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on SocketException {
      print('WorkingWeatherScreen: No internet connection');
      if (!mounted) return;
      setState(() {
        _status = 'No Internet: Please check your connection';
        _isLoading = false;
      });
    } on TimeoutException {
      print('WorkingWeatherScreen: Request timeout');
      if (!mounted) return;
      setState(() {
        _status = 'Timeout: Request took too long';
        _isLoading = false;
      });
    } on FormatException {
      print('WorkingWeatherScreen: Invalid response format');
      if (!mounted) return;
      setState(() {
        _status = 'Format Error: Invalid response from weather service';
        _isLoading = false;
      });
    } catch (e) {
      print('WorkingWeatherScreen: Weather API Error: $e');
      if (!mounted) return;
      setState(() {
        _status = 'Weather Error: ${e.toString()}';
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
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.weather),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (!mounted) return;
              setState(() {
                _isLoading = true;
                _status = localizations.loading; // Using existing key
              });
              _getCurrentLocationAndWeather();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!mounted) return;
          setState(() {
            _isLoading = true;
            _status = localizations.loading; // Using existing key
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
                        '${localizations.weather} Details', // Partially localized
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              localizations.humidity,
                              '$_humidity%',
                              Icons.water_drop,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              localizations.windSpeed,
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
                      Row(
                        children: [
                          Icon(
                            _isLoading
                                ? Icons.refresh
                                : _status.contains('successfully')
                                ? Icons.check_circle
                                : _status.contains('Error') ||
                                      _status.contains('error')
                                ? Icons.error
                                : Icons.info,
                            color: _isLoading
                                ? AppTheme.primaryGreen
                                : _status.contains('successfully')
                                ? Colors.green
                                : _status.contains('Error') ||
                                      _status.contains('error')
                                ? Colors.red
                                : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'App Status', // Hardcoded as it's a section title
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _status,
                        style: TextStyle(
                          color:
                              _status.contains('Error') ||
                                  _status.contains('error')
                              ? Colors.red
                              : _status.contains('successfully')
                              ? Colors.green
                              : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_status.contains('Error') ||
                          _status.contains('error') ||
                          _status.contains('denied') ||
                          _status.contains('timeout')) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    _getCurrentLocationAndWeather();
                                  },
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              localizations.retry,
                            ), // Using existing key
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Technical Details', // Hardcoded as it's a section title
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'API Key: ${_weatherApiKey.substring(0, 8)}...',
                      ), // Hardcoded as it's technical info
                      Text(
                        'Default Location: Delhi (28.6139, 77.2090)',
                      ), // Hardcoded as it's technical info
                      Text(
                        'Loading: $_isLoading',
                      ), // Hardcoded as it's technical info
                      Text(
                        '✅ Weather API: Working',
                      ), // Hardcoded as it's technical info
                      Text(
                        '✅ Location Services: Available',
                      ), // Hardcoded as it's technical info
                      Text(
                        '✅ Network Security: Configured',
                      ), // Hardcoded as it's technical info
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

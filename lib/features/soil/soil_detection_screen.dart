import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/models/soil.dart';
import '../../core/services/soil_service.dart';
import '../../shared/theme/app_theme.dart';

class SoilDetectionScreen extends StatefulWidget {
  const SoilDetectionScreen({super.key});

  @override
  State<SoilDetectionScreen> createState() => _SoilDetectionScreenState();
}

class _SoilDetectionScreenState extends State<SoilDetectionScreen> {
  SoilAnalysis? _currentAnalysis;
  List<SoilAnalysis> _nearbyAnalyses = [];
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _detectSoilType();
  }

  Future<void> _detectSoilType() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location
      _currentPosition = await SoilDetectionService.getCurrentLocation();

      // Detect soil type
      final analysis = await SoilDetectionService.detectSoilType(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Get nearby analyses
      final nearby = await SoilDetectionService.getNearbyAnalyses(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      setState(() {
        _currentAnalysis = analysis;
        _nearbyAnalyses = nearby;
        _isLoading = false;
      });

      // Save analysis
      await SoilDetectionService.saveSoilAnalysis(analysis);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Type Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _detectSoilType,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Detecting soil type...'),
            SizedBox(height: 8),
            Text(
              'Using your location to analyze soil composition',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text(
              'Error detecting soil type',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _detectSoilType,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_currentAnalysis == null) {
      return const Center(child: Text('No soil analysis available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationCard(),
          const SizedBox(height: 16),
          _buildSoilTypeCard(),
          const SizedBox(height: 16),
          _buildCharacteristicsCard(),
          const SizedBox(height: 16),
          _buildSuitableCropsCard(),
          const SizedBox(height: 16),
          _buildRecommendationsCard(),
          if (_nearbyAnalyses.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNearbyAnalysesCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Detection Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_currentAnalysis!.location),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Coordinates: ${_currentAnalysis!.latitude.toStringAsFixed(4)}, ${_currentAnalysis!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Analyzed: ${_formatDateTime(_currentAnalysis!.analyzedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilTypeCard() {
    final soilType = _currentAnalysis!.soilType;
    final confidence = _currentAnalysis!.additionalData['confidence'] ?? 0.75;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(soilType.color.substring(1), radix: 16) +
                          0xFF000000,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    soilType.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(confidence * 100).toInt()}% confident',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              soilType.description,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSoilProperty(
                    'pH Level',
                    soilType.phRange.toString(),
                  ),
                ),
                Expanded(
                  child: _buildSoilProperty('Fertility', soilType.fertility),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSoilProperty('Drainage', soilType.drainage),
                ),
                Expanded(
                  child: _buildSoilProperty('Texture', soilType.texture),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilProperty(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCharacteristicsCard() {
    final characteristics = _currentAnalysis!.soilType.characteristics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soil Characteristics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...characteristics.map(
              (characteristic) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(characteristic)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuitableCropsCard() {
    final crops = _currentAnalysis!.soilType.suitableCrops;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suitable Crops',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: crops
                  .map(
                    (crop) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.secondaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        crop,
                        style: const TextStyle(
                          color: AppTheme.secondaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final soilType = _currentAnalysis!.soilType;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farming Recommendations',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRecommendation(
              Icons.water_drop,
              'Irrigation',
              _getIrrigationRecommendation(soilType),
            ),
            _buildRecommendation(
              Icons.eco,
              'Fertilization',
              _getFertilizationRecommendation(soilType),
            ),
            _buildRecommendation(
              Icons.agriculture,
              'Cultivation',
              _getCultivationRecommendation(soilType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation(
    IconData icon,
    String title,
    String recommendation,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  recommendation,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyAnalysesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby Soil Reports',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._nearbyAnalyses.map(
              (analysis) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                            analysis.soilType.color.substring(1),
                            radix: 16,
                          ) +
                          0xFF000000,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(analysis.soilType.name),
                subtitle: Text(analysis.location),
                trailing: Text(
                  _formatDate(analysis.analyzedAt),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIrrigationRecommendation(DetailedSoilType soilType) {
    switch (soilType.id) {
      case 'alluvial':
        return 'Moderate irrigation needed. Good water retention capacity.';
      case 'black':
        return 'Less frequent but deep irrigation. Excellent water retention.';
      case 'red':
        return 'Regular irrigation required. Improve with organic matter.';
      case 'laterite':
        return 'Frequent irrigation needed. Poor water retention.';
      case 'desert':
        return 'Drip irrigation recommended. Very poor water retention.';
      case 'mountain':
        return 'Natural rainfall usually sufficient. Monitor moisture levels.';
      default:
        return 'Adjust irrigation based on crop requirements and season.';
    }
  }

  String _getFertilizationRecommendation(DetailedSoilType soilType) {
    switch (soilType.id) {
      case 'alluvial':
        return 'Add nitrogen and organic matter. Phosphorus and potash adequate.';
      case 'black':
        return 'Add nitrogen and phosphorus. Rich in lime and magnesium.';
      case 'red':
        return 'Add lime to reduce acidity. Nitrogen and phosphorus needed.';
      case 'laterite':
        return 'Heavy fertilization required. Add NPK and organic matter.';
      case 'desert':
        return 'Improve with organic matter first, then add balanced NPK.';
      case 'mountain':
        return 'Add lime if too acidic. Organic matter beneficial.';
      default:
        return 'Soil test recommended for specific fertilizer requirements.';
    }
  }

  String _getCultivationRecommendation(DetailedSoilType soilType) {
    switch (soilType.id) {
      case 'alluvial':
        return 'Excellent for most crops. Deep plowing beneficial.';
      case 'black':
        return 'Wait for proper moisture. Avoid working when too wet or dry.';
      case 'red':
        return 'Contour farming recommended. Prevent erosion.';
      case 'laterite':
        return 'Improve structure with organic matter. Avoid over-tilling.';
      case 'desert':
        return 'Sand dune stabilization needed. Windbreak recommended.';
      case 'mountain':
        return 'Terracing recommended. Prevent soil erosion.';
      default:
        return 'Follow sustainable farming practices for soil conservation.';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

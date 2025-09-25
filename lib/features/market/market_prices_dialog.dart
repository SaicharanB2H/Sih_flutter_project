import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../shared/theme/app_theme.dart';

class MarketPricesDialog extends StatefulWidget {
  const MarketPricesDialog({super.key});

  @override
  State<MarketPricesDialog> createState() => _MarketPricesDialogState();
}

class _MarketPricesDialogState extends State<MarketPricesDialog> {
  List<MarketPrice> _marketPrices = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _statusMessage = 'Fetching real-time market prices...';

  @override
  void initState() {
    super.initState();
    _loadMarketPrices();
  }

  Future<void> _loadMarketPrices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _statusMessage = 'Connecting to market data service...';
    });

    try {
      setState(() {
        _statusMessage = 'Analyzing current market trends...';
      });

      final prices = await MarketPriceService.getRealTimeMarketPrices();

      if (mounted) {
        setState(() {
          _marketPrices = prices;
          _isLoading = false;
          _statusMessage = 'Market data updated successfully!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          _statusMessage = 'Failed to load market data';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Real-Time Market Prices',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Powered by AI',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage.isNotEmpty
                  ? _buildErrorState()
                  : _buildMarketPricesList(),
            ),

            // Footer with refresh button
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    if (MarketPriceService.hasCachedData)
                      Text(
                        'Last updated: ${_getTimeAgo(MarketPriceService.lastFetchTime!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _loadMarketPrices,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _statusMessage,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds...',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Market Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadMarketPrices,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketPricesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _marketPrices.length,
      itemBuilder: (context, index) {
        final price = _marketPrices[index];
        return _buildPriceCard(price);
      },
    );
  }

  Widget _buildPriceCard(MarketPrice price) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Crop icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getCropColor(price.cropName).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCropIcon(price.cropName),
                color: _getCropColor(price.cropName),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Crop info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price.cropName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price.marketName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (price.grade != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        price.grade!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.secondaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${price.pricePerKg.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'per ${price.unit.name}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCropIcon(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'rice':
        return Icons.grain;
      case 'wheat':
        return Icons.grass;
      case 'tomato':
        return Icons.local_florist;
      case 'onion':
        return Icons.circle_outlined;
      case 'potato':
        return Icons.circle;
      case 'cotton':
        return Icons.cloud_outlined;
      case 'sugarcane':
        return Icons.height;
      case 'maize':
      case 'corn':
        return Icons.grain;
      case 'soybean':
        return Icons.eco;
      default:
        return Icons.agriculture;
    }
  }

  Color _getCropColor(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'rice':
        return Colors.amber;
      case 'wheat':
        return Colors.orange;
      case 'tomato':
        return Colors.red;
      case 'onion':
        return Colors.purple;
      case 'potato':
        return Colors.brown;
      case 'cotton':
        return Colors.grey;
      case 'sugarcane':
        return Colors.green;
      case 'maize':
      case 'corn':
        return Colors.yellow;
      case 'soybean':
        return Colors.lightGreen;
      default:
        return AppTheme.primaryGreen;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} day ago';
    }
  }
}

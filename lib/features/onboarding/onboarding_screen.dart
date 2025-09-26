import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/simple_auth_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _formKey = GlobalKey<FormState>();

  // Farm details
  final _farmNameController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final List<String> _selectedCrops = [];

  final List<String> _cropOptions = [
    'Rice',
    'Wheat',
    'Corn',
    'Tomato',
    'Potato',
    'Onion',
    'Cotton',
    'Sugarcane',
    'Soybean',
    'Millet',
  ];

  @override
  void dispose() {
    _farmNameController.dispose();
    _farmSizeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() {
    // For the crop selection page, we only need to check if crops are selected
    if (_currentPage == 2) {
      if (_selectedCrops.isNotEmpty) {
        // Complete onboarding
        final authProvider = Provider.of<SimpleAuthProvider>(
          context,
          listen: false,
        );
        authProvider.completeOnboarding();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farm setup completed successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        // Navigate to home screen after a short delay to ensure state update
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one crop'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } else {
      // For other pages, validate the form
      if (_formKey.currentState!.validate()) {
        _nextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (_currentPage > 0) {
          _previousPage();
          return false; // Don't pop the route
        }
        return true; // Allow popping if on first page
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.farmDetails),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          leading: _currentPage > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousPage,
                )
              : null,
          actions: [
            // Language selection button in app bar
            PopupMenuButton<String>(
              icon: const Icon(Icons.language),
              onSelected: (String languageCode) {
                languageProvider.changeLanguage(languageCode);
              },
              itemBuilder: (BuildContext context) {
                return languageProvider.supportedLanguagesList.map((entry) {
                  return PopupMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value['nativeName']!,
                      style: TextStyle(
                        fontWeight:
                            entry.key == languageProvider.locale.languageCode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? AppTheme.primaryGreen
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page content - Wrapped in Expanded
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(localizations),
                  _buildFarmDetailsPage(localizations),
                  _buildCropSelectionPage(localizations),
                ],
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: Text(localizations.back),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Use _currentPage instead of _pageController.page
                        if (_currentPage == 2) {
                          _finishOnboarding();
                        } else if (_currentPage == 1) {
                          // Validate form before moving to next page
                          if (_formKey.currentState!.validate()) {
                            _nextPage();
                          }
                        } else {
                          _nextPage();
                        }
                      },
                      child: Text(
                        _currentPage == 2
                            ? localizations.finish
                            : localizations.next,
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

  Widget _buildWelcomePage(AppLocalizations localizations) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.agriculture,
              size: 100,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 32),
            Text(
              localizations.welcome,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.weWillAutomaticallyDetectSoilTypeTitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Made the container with info text smaller to prevent overflow
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightGreen),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryGreen),
                  const SizedBox(height: 8),
                  Text(
                    localizations.weWillAutomaticallyDetectSoilType,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmDetailsPage(AppLocalizations localizations) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.farmDetails,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.farmDetailsDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _farmNameController,
                decoration: InputDecoration(
                  labelText: localizations.farmName,
                  prefixIcon: const Icon(Icons.agriculture),
                  hintText: localizations.enterFarmName,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return localizations.farmName;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _farmSizeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localizations.farmSize,
                  prefixIcon: const Icon(Icons.straighten),
                  hintText: localizations.enterFarmSize,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return localizations.farmSize;
                  }
                  final size = double.tryParse(value);
                  if (size == null || size <= 0) {
                    return localizations.enterFarmSize;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropSelectionPage(AppLocalizations localizations) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.primaryCrops,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.pleaseSelectAtLeastOneCrop,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Fixed height GridView for crop selection
            SizedBox(
              height: 300, // Set a fixed height for the GridView
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _cropOptions.length,
                itemBuilder: (context, index) {
                  final crop = _cropOptions[index];
                  final isSelected = _selectedCrops.contains(crop);

                  return FilterChip(
                    label: Text(
                      _getLocalizedCropName(crop, localizations),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCrops.add(crop);
                        } else {
                          _selectedCrops.remove(crop);
                        }
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppTheme.primaryGreen,
                    checkmarkColor: Colors.white,
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            if (_selectedCrops.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: AppTheme.errorRed,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localizations.pleaseSelectAtLeastOneCrop,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedCrops.length} ${localizations.cropsSelected}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successGreen,
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

  String _getLocalizedCropName(String crop, AppLocalizations localizations) {
    switch (crop.toLowerCase()) {
      case 'rice':
        return localizations.rice;
      case 'wheat':
        return localizations.wheat;
      case 'corn':
        return localizations.corn;
      case 'tomato':
        return localizations.tomato;
      case 'potato':
        return localizations.potato;
      case 'onion':
        return localizations.onion;
      case 'cotton':
        return localizations.cotton;
      case 'sugarcane':
        return localizations.sugarcane;
      case 'soybean':
        return localizations.soybean;
      case 'millet':
        return localizations.millet;
      default:
        return crop;
    }
  }
}

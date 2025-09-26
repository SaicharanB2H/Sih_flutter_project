import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/simple_auth_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../features/diagnosis/diagnosis_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/weather/working_weather_screen.dart';
import '../../features/soil/soil_detection_screen.dart';
import '../../features/market/market_prices_dialog.dart';
import '../../features/settings/language_settings_screen.dart';
import '../../features/auth/mobile_sign_in_screen.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardTab(
        onNavigate: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const DiagnosisScreen(),
      const ChatScreen(),
      const WorkingWeatherScreen(),
      const ProfileTab(),
    ];

    return WillPopScope(
      onWillPop: () async {
        // Show exit confirmation dialog
        return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.appTitle),
                content: const Text('Do you want to exit the app?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: Scaffold(
        body: screens[_selectedIndex],
        bottomNavigationBar: Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context)!;
            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard),
                  label: localizations.dashboard,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.local_hospital),
                  label: localizations.plantDiagnosis,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.chat),
                  label: localizations.chat,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.wb_sunny),
                  label: localizations.weather,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: localizations.profile,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final Function(int) onNavigate;

  const DashboardTab({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<SimpleAuthProvider>(
              builder: (context, authProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryGreen,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${localizations.welcome}, ${authProvider.user?.name ?? 'Farmer'}!',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ready to optimize your farming?',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.camera_alt,
                  title: localizations.plantDiagnosis,
                  subtitle: localizations.capturePhoto,
                  color: AppTheme.primaryBlue,
                  onTap: () {
                    // Navigate to diagnosis tab
                    onNavigate(1);
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.chat,
                  title: localizations.askQuestion,
                  subtitle: localizations.askAnything,
                  color: AppTheme.primaryGreen,
                  onTap: () {
                    // Navigate to chat tab
                    onNavigate(2);
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.wb_sunny,
                  title: localizations.weather,
                  subtitle: localizations.forecast,
                  color: AppTheme.warningOrange,
                  onTap: () {
                    // Navigate to weather tab
                    onNavigate(3);
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.landscape,
                  title: localizations.soilType,
                  subtitle: localizations.soilType,
                  color: Color(0xFF8B4513),
                  onTap: () {
                    // Navigate to soil detection screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SoilDetectionScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.trending_up,
                  title: localizations.marketPrices,
                  subtitle: localizations.marketPrices,
                  color: AppTheme.secondaryGreen,
                  onTap: () {
                    // Show real-time market prices dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const MarketPricesDialog(),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.info,
                        color: AppTheme.primaryBlue,
                      ),
                      title: Text('Welcome to AgriAdvisor AI'),
                      subtitle: Text('Start by adding your farm details'),
                      trailing: Text(
                        'Today',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiagnosisTab extends StatelessWidget {
  const DiagnosisTab({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.plantDiagnosis)),
      body: Center(child: Text(localizations.comingSoon)),
    );
  }
}

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.chat)),
      body: Center(child: Text(localizations.comingSoon)),
    );
  }
}

class WeatherTab extends StatelessWidget {
  const WeatherTab({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.weather)),
      body: Center(child: Text(localizations.comingSoon)),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.profile)),
      body: Consumer<SimpleAuthProvider>(
        builder: (context, authProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryGreen,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authProvider.user?.name ?? 'User',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        authProvider.user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ListTile(
                leading: const Icon(Icons.language),
                title: Text(localizations.language),
                subtitle: Text(languageProvider.currentLanguageNativeName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageSettingsScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(localizations.notifications),
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.help),
                title: Text(localizations.help),
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.info),
                title: Text(localizations.about),
                onTap: () {},
              ),

              const SizedBox(height: 24),

              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.errorRed),
                title: Text(
                  localizations.signOut,
                  style: TextStyle(color: AppTheme.errorRed),
                ),
                onTap: () async {
                  final authProvider = Provider.of<SimpleAuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProvider.signOut();
                  
                  // Navigate back to sign in screen
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MobileSignInScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

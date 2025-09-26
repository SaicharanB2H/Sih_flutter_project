import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../core/providers/simple_auth_provider.dart';
import '../../core/services/storage_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  DiagnosisResult? _result;
  List<DiagnosisResult> _recentDiagnoses = [];

  // Gemini API key for image analysis
  final String _geminiApiKey = 'AIzaSyDjghcnRP4_WmY3HxkGZPnVJg-hMEbKtJw';

  @override
  void initState() {
    super.initState();
    _loadRecentDiagnoses();
  }

  Future<void> _loadRecentDiagnoses() async {
    try {
      final diagnoses = await StorageService.getAllDiagnosisHistory();
      setState(() {
        _recentDiagnoses = diagnoses
            .map(
              (history) => DiagnosisResult(
                condition: history.diagnosis,
                type: history.cropType,
                confidence: history.confidence,
                description: history.symptoms.isNotEmpty
                    ? history.symptoms.first
                    : '',
                treatments: history.recommendations,
              ),
            )
            .toList();
      });
    } catch (e) {
      print('Failed to load recent diagnoses: $e');
      setState(() {
        _recentDiagnoses = [];
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = photo;
          _result = null; // Clear previous results
        });
        _analyzeImage();
      }
    } catch (e) {
      _showErrorDialog('Failed to capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _result = null; // Clear previous results
        });
        _analyzeImage();
      }
    } catch (e) {
      _showErrorDialog('Failed to select image: $e');
    }
  }

  String? _currentBase64Image; // Add this field to store current image

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Convert image to base64
      final bytes = await File(_selectedImage!.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      _currentBase64Image = base64Image; // Store for later use

      // Call Gemini API for image analysis
      final result = await _analyzeImageWithGemini(base64Image);

      setState(() {
        _isAnalyzing = false;
        _result = result;
      });

      // Save to storage
      await _saveDiagnosisToStorage(base64Image, result);
      _loadRecentDiagnoses();

      _showResultDialog();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorDialog('Analysis failed: ${e.toString()}');
    }
  }

  Future<DiagnosisResult> _analyzeImageWithGemini(String base64Image) async {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    // Map locale codes to language names for the AI prompt
    final languageMap = {
      'en': 'English',
      'as': 'Assamese',
      'bn': 'Bengali',
      'gu': 'Gujarati',
      'hi': 'Hindi',
      'kn': 'Kannada',
      'ml': 'Malayalam',
      'mr': 'Marathi',
      'or': 'Odia',
      'pa': 'Punjabi',
      'ta': 'Tamil',
      'te': 'Telugu',
    };

    final userLanguage = languageMap[locale] ?? 'English';

    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

    print('Starting Gemini API call...');
    print('API URL: $apiUrl?key=HIDDEN');
    print('Image data length: ${base64Image.length}');

    final headers = {'Content-Type': 'application/json'};

    final body = json.encode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'You are an expert agricultural AI assistant. Analyze this plant image for diseases, pests, or health issues. Provide the response in $userLanguage language only.\n\nProvide:\n1. Diagnosis (specific condition name)\n2. Type (Healthy/Disease/Pest/Nutrient Deficiency)\n3. Confidence level (0-1)\n4. Detailed description\n5. List of specific treatment recommendations\n6. Also recommend the fertilizers and pesticides\n\nFormat your response as JSON with these exact keys: condition, type, confidence, description, treatments (array of strings)',
            },
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.3,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1000,
      },
    });

    final response = await http.post(
      Uri.parse('$apiUrl?key=$_geminiApiKey'),
      headers: headers,
      body: body,
    );

    print('Gemini API response status: ${response.statusCode}');
    print('Gemini API response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        String responseText =
            data['candidates'][0]['content']['parts'][0]['text'];

        print('Gemini response text: $responseText');

        // Try to parse JSON response
        try {
          // Extract JSON from response if it's wrapped in code
          if (responseText.contains('```json')) {
            responseText = responseText
                .split('```json')[1]
                .split('```')[0]
                .trim();
          } else if (responseText.contains('{')) {
            // Find the JSON part
            int startIndex = responseText.indexOf('{');
            int endIndex = responseText.lastIndexOf('}') + 1;
            responseText = responseText.substring(startIndex, endIndex);
          }

          final analysisData = json.decode(responseText);

          return DiagnosisResult(
            condition:
                analysisData['condition'] ?? localizations.unknownCondition,
            type: analysisData['type'] ?? localizations.unknown,
            confidence: (analysisData['confidence'] ?? 0.5).toDouble(),
            description:
                analysisData['description'] ?? localizations.analysisCompleted,
            treatments: List<String>.from(analysisData['treatments'] ?? []),
          );
        } catch (e) {
          print('JSON parsing error: $e');
          // Fallback: parse the text response manually
          return _parseTextResponse(responseText);
        }
      }
    } else {
      print('Gemini API error: ${response.statusCode} - ${response.body}');
    }

    throw Exception('Failed to analyze image with Gemini API');
  }

  // Helper method to localize condition
  String _localizeCondition(String condition) {
    final localizations = AppLocalizations.of(context)!;

    // Map common conditions to localized strings
    switch (condition.toLowerCase()) {
      case 'healthy':
        return localizations.plantHealthy;
      case 'bacterial leaf blight':
        return localizations.bacterialLeafBlight;
      case 'brown spot':
        return localizations.brownSpot;
      case 'leaf blast':
        return localizations.leafBlast;
      case 'leaf scald':
        return localizations.leafScald;
      case 'narrow brown spot':
        return localizations.narrowBrownSpot;
      case 'sheath blight':
        return localizations.sheathBlight;
      case 'stem rot':
        return localizations.stemRot;
      case 'yellow stem borer':
        return localizations.yellowStemBorer;
      case 'brown plant hopper':
        return localizations.brownPlantHopper;
      case 'gall midge':
        return localizations.gallMidge;
      case 'rice hispa':
        return localizations.riceHispa;
      case 'leaf folder':
        return localizations.leafFolder;
      case 'nitrogen deficiency':
        return localizations.nitrogenDeficiency;
      case 'phosphorus deficiency':
        return localizations.phosphorusDeficiency;
      case 'potassium deficiency':
        return localizations.potassiumDeficiency;
      case 'zinc deficiency':
        return localizations.zincDeficiency;
      case 'iron deficiency':
        return localizations.ironDeficiency;
      default:
        return condition; // Return original if no localization found
    }
  }

  // Helper method to localize type
  String _localizeType(String type) {
    final localizations = AppLocalizations.of(context)!;

    switch (type.toLowerCase()) {
      case 'healthy':
        return localizations.healthy;
      case 'disease':
        return localizations.disease;
      case 'pest':
        return localizations.pest;
      case 'nutrient deficiency':
        return localizations.nutrientDeficiency;
      default:
        return type;
    }
  }

  // Helper method to localize treatments
  List<String> _localizeTreatments(List<String> treatments) {
    final localizations = AppLocalizations.of(context)!;
    final List<String> localizedTreatments = [];

    for (String treatment in treatments) {
      // Try to localize common treatments
      String localized = _localizeTreatment(treatment);
      localizedTreatments.add(localized);
    }

    return localizedTreatments;
  }

  // Helper method to localize a single treatment
  String _localizeTreatment(String treatment) {
    final localizations = AppLocalizations.of(context)!;

    // Map common treatments to localized strings
    if (treatment.toLowerCase().contains('spray')) {
      return treatment.replaceAll(
        RegExp(r'spray', caseSensitive: false),
        localizations.spray,
      );
    } else if (treatment.toLowerCase().contains('fertilizer')) {
      return treatment.replaceAll(
        RegExp(r'fertilizer', caseSensitive: false),
        localizations.fertilizer,
      );
    } else if (treatment.toLowerCase().contains('pesticide')) {
      return treatment.replaceAll(
        RegExp(r'pesticide', caseSensitive: false),
        localizations.pesticide,
      );
    } else if (treatment.toLowerCase().contains('water')) {
      return treatment.replaceAll(
        RegExp(r'water', caseSensitive: false),
        localizations.water,
      );
    } else if (treatment.toLowerCase().contains('pruning')) {
      return treatment.replaceAll(
        RegExp(r'pruning', caseSensitive: false),
        localizations.pruning,
      );
    }

    return treatment; // Return original if no localization found
  }

  DiagnosisResult _parseTextResponse(String response) {
    final localizations = AppLocalizations.of(context)!;

    // Simple text parsing fallback
    final lines = response.split('\n');
    String condition = localizations.plantAnalysisComplete;
    String type = localizations.analysis;
    double confidence = 0.8;
    String description = response;
    List<String> treatments = [];

    // Try to extract treatments from bullet points or numbered lists
    for (String line in lines) {
      if (line.trim().startsWith('•') ||
          line.trim().startsWith('-') ||
          RegExp(r'^\d+\.').hasMatch(line.trim())) {
        treatments.add(line.trim().replaceFirst(RegExp(r'^[•\-\d+\.]\s*'), ''));
      }
    }

    return DiagnosisResult(
      condition: condition,
      type: type,
      confidence: confidence,
      description: description,
      treatments: treatments.isEmpty
          ? [localizations.consultAgriculturalExpert]
          : treatments,
    );
  }

  Future<void> _saveDiagnosisToStorage(
    String base64Image,
    DiagnosisResult result,
  ) async {
    try {
      await StorageService.saveDiagnosis(
        imageBase64: base64Image,
        diagnosis: result.condition,
        treatment: result.treatments.join('; '),
        cropType: 'Unknown', // Could be enhanced to detect crop type
        confidence: result.confidence,
        symptoms: [result.description],
        recommendations: result.treatments,
      );
    } catch (e) {
      print('Failed to save diagnosis: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Camera',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBlue),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.photo_library,
                            size: 48,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showResultDialog() {
    if (_result == null) return;

    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconForType(_result!.type),
              color: _getColorForType(_result!.type),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(_result!.condition)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorForType(_result!.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${localizations.confidence}: ${(_result!.confidence * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getColorForType(_result!.type),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _result!.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              if (_result!.treatments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  localizations.treatments,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_result!.treatments.map(
                  (treatment) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(treatment)),
                      ],
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentBase64Image != null) {
                _saveDiagnosisToStorage(_currentBase64Image!, _result!);
              }
            },
            child: Text(localizations.saveToHistory),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle;
      case 'disease':
        return Icons.local_hospital;
      case 'pest':
        return Icons.bug_report;
      case 'nutrient deficiency':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'healthy':
        return AppTheme.successGreen;
      case 'disease':
        return AppTheme.errorRed;
      case 'pest':
        return AppTheme.warningOrange;
      case 'nutrient deficiency':
        return Colors.amber;
      default:
        return AppTheme.textSecondary;
    }
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Diagnosis History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _recentDiagnoses.isEmpty
                    ? const Center(
                        child: Text('No diagnosis history available'),
                      )
                    : ListView.builder(
                        itemCount: _recentDiagnoses.length,
                        itemBuilder: (context, index) {
                          final diagnosis = _recentDiagnoses[index];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                _getIconForType(diagnosis.type),
                                color: _getColorForType(diagnosis.type),
                              ),
                              title: Text(diagnosis.condition),
                              subtitle: Text(
                                '${(diagnosis.confidence * 100).toStringAsFixed(0)}% confidence\n${diagnosis.description}',
                              ),
                              isThreeLine: true,
                              onTap: () {
                                // Show full details
                                _showDiagnosisDetails(diagnosis);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiagnosisDetails(DiagnosisResult diagnosis) {
    Navigator.pop(context); // Close history dialog first

    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconForType(diagnosis.type),
              color: _getColorForType(diagnosis.type),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(diagnosis.condition)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorForType(diagnosis.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${localizations.confidence}: ${(diagnosis.confidence * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getColorForType(diagnosis.type),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                diagnosis.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (diagnosis.treatments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  localizations.treatments,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...diagnosis.treatments.map(
                  (treatment) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(treatment)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.plantDiagnosis),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          localizations.howToGetBestResults,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('• ${localizations.takeClearWellLitPhotos}'),
                    Text('• ${localizations.focusOnAffectedAreas}'),
                    Text('• ${localizations.includeLeavesStemsFruits}'),
                    Text('• ${localizations.avoidBlurryDarkImages}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Image Display
            if (_selectedImage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImage!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isAnalyzing)
                        Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(localizations.analyzing),
                          ],
                        )
                      else if (_result != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getColorForType(
                              _result!.type,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getColorForType(
                                _result!.type,
                              ).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getIconForType(_result!.type),
                                color: _getColorForType(_result!.type),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _result!.condition,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '${localizations.confidence}: ${(_result!.confidence * 100).toStringAsFixed(1)}%',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: _showResultDialog,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Action Button
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _showImageSourceDialog,
              icon: const Icon(Icons.camera_alt),
              label: Text(
                _selectedImage == null
                    ? localizations.capturePhoto
                    : '${localizations.capturePhoto} Again', // Using existing key with "Again" added
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            // Recent Diagnoses
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations.history,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_recentDiagnoses.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              // Show history screen
                              _showHistoryDialog();
                            },
                            child: Text(localizations.viewAll),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _recentDiagnoses.isEmpty
                        ? Center(
                            child: Text(
                              localizations.noPreviousDiagnoses,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : Column(
                            children: _recentDiagnoses.take(3).map((diagnosis) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getColorForType(
                                    diagnosis.type,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getColorForType(
                                      diagnosis.type,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getIconForType(diagnosis.type),
                                      color: _getColorForType(diagnosis.type),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            diagnosis.condition,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${localizations.confidence}: ${(diagnosis.confidence * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
}

class DiagnosisResult {
  final String condition;
  final String type;
  final double confidence;
  final String description;
  final List<String> treatments;

  DiagnosisResult({
    required this.condition,
    required this.type,
    required this.confidence,
    required this.description,
    required this.treatments,
  });
}

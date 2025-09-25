import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import '../../core/services/storage_service.dart';
import '../../shared/theme/app_theme.dart';

// Map Indian states/UTs -> STT locale (underscore style) and TTS (converted to BCP-47 with hyphen)
const Map<String, String> _stateToLocale = {
  // South
  'Tamil Nadu': 'ta_IN',
  'Karnataka': 'kn_IN',
  'Kerala': 'ml_IN',
  'Andhra Pradesh': 'te_IN',
  'Telangana': 'te_IN',
  'Puducherry': 'ta_IN',
  'Lakshadweep': 'ml_IN',
  // West
  'Maharashtra': 'mr_IN',
  'Goa': 'en_IN', // device TTS often lacks Konkani; fallback to English India
  'Gujarat': 'gu_IN',
  'Dadra and Nagar Haveli and Daman and Diu': 'gu_IN',
  // East
  'Odisha': 'or_IN',
  'West Bengal': 'bn_IN',
  'Andaman and Nicobar Islands': 'en_IN',
  // North/North-Central
  'Delhi': 'hi_IN',
  'Haryana': 'hi_IN',
  'Punjab': 'pa_IN',
  'Himachal Pradesh': 'hi_IN',
  'Jammu and Kashmir': 'hi_IN',
  'Ladakh': 'hi_IN',
  'Rajasthan': 'hi_IN',
  'Uttar Pradesh': 'hi_IN',
  'Uttarakhand': 'hi_IN',
  'Madhya Pradesh': 'hi_IN',
  'Chhattisgarh': 'hi_IN',
  'Bihar': 'hi_IN',
  'Jharkhand': 'hi_IN',
  // North‑East
  'Assam': 'as_IN',
  'Sikkim': 'en_IN',
  'Meghalaya': 'en_IN',
  'Mizoram': 'en_IN',
  'Nagaland': 'en_IN',
  'Manipur': 'en_IN',
  'Arunachal Pradesh': 'en_IN',
  'Tripura': 'bn_IN',
};

Future<Position> _getPosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) throw Exception('Location services disabled');
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('Location permission denied');
  }
  return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
}

Future<(String countryCode, String? state)> _getRegion() async {
  final pos = await _getPosition();
  final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
  final m = marks.first;
  final cc = (m.isoCountryCode ?? '').toUpperCase();
  final state = m.administrativeArea; // often state/UT name
  return (cc.isEmpty ? 'IN' : cc, state);
}

String _normalizeState(String? s) {
  if (s == null) return '';
  return s.trim();
}

String _pickLocaleForRegion(String countryCode, String? state) {
  // Prioritize India mappings; else fallback to device locale or en_IN
  if (countryCode == 'IN') {
    final st = _normalizeState(state);
    // exact match
    if (_stateToLocale.containsKey(st)) return _stateToLocale[st]!;
    // heuristic substring checks (handles variants like NCT of Delhi)
    final lower = st.toLowerCase();
    if (lower.contains('delhi')) return 'hi_IN';
    if (lower.contains('tamil')) return 'ta_IN';
    if (lower.contains('karnataka')) return 'kn_IN';
    if (lower.contains('kerala')) return 'ml_IN';
    if (lower.contains('andhra')) return 'te_IN';
    if (lower.contains('telangana')) return 'te_IN';
    if (lower.contains('maharashtra')) return 'mr_IN';
    if (lower.contains('gujarat')) return 'gu_IN';
    if (lower.contains('odisha') || lower.contains('orissa')) return 'or_IN';
    if (lower.contains('bengal')) return 'bn_IN';
    if (lower.contains('assam')) return 'as_IN';
    if (lower.contains('punjab')) return 'pa_IN';
    // default within India
    return 'hi_IN';
  }
  // Fallback to device locale or en_IN
  final device = ui.PlatformDispatcher.instance.locale; // e.g., en_IN
  final devStr = '${device.languageCode}_${device.countryCode ?? 'IN'}';
  return devStr.isNotEmpty ? devStr : 'en_IN';
}

String _toBcp47(String underscoreLocale) {
  // speech_to_text uses underscore, flutter_tts prefers hyphen (BCP-47)
  return underscoreLocale.replaceAll('_', '-'); // e.g., hi-IN
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTyping = false;
  String _apiKey = 'AIzaSyDjghcnRP4_WmY3HxkGZPnVJg-hMEbKtJw';
  File? _selectedImage;

  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';

  // Text to speech variables
  late FlutterTts _tts;
  bool _ttsEnabled = false;
  bool _isSpeaking = false;

  // Location-based locale variables
  String _chosenLocale = 'en_IN'; // STT localeId
  String _chosenBcp47 = 'en-IN'; // TTS language
  String _regionLabel = 'Detecting location...';
  bool _localeReady = false;

  @override
  void initState() {
    super.initState();
    _initLocationBasedVoice();
    _messages.add(
      ChatMessage(
        text:
            'Hello! I\'m your Agrow AI assistant powered by Gemini 2.0! How can I help you with your farming today? You can also send me photos of your crops for analysis and suggestions, or use voice input by tapping the microphone! I can also read my responses aloud in your local language.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    if (_speech.isListening) {
      _speech.stop();
    }
    if (_isSpeaking) {
      _tts.stop();
    }
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final userMessage = ChatMessage(
      text: text.isNotEmpty ? text : 'Photo analysis request',
      isUser: true,
      timestamp: DateTime.now(),
      imageFile: _selectedImage,
    );

    setState(() {
      _messages.add(userMessage);
    });

    _messageController.clear();
    final imageToSend = _selectedImage;
    setState(() {
      _selectedImage = null;
    });

    await _getAIResponse(
      text.isNotEmpty
          ? text
          : 'Analyze this crop image and provide farming advice',
      imageToSend,
    );
  }

  Future<void> _getAIResponse(String userMessage, [File? imageFile]) async {
    setState(() {
      _isTyping = true;
    });

    try {
      final response = await _callGemini(userMessage, imageFile);

      if (mounted) {
        final aiMessage = ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        );

        setState(() {
          _isTyping = false;
          _messages.add(aiMessage);
        });

        // Save chat to storage
        await _saveChatToStorage(userMessage, response);

        // Read the AI response aloud using TTS
        if (_ttsEnabled && _localeReady) {
          await _speakText(response);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text:
                  'Sorry, I encountered an error while processing your request. Please check your API key and internet connection.\n\nError: ${e.toString()}',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  Future<String> _callGemini(String message, [File? imageFile]) async {
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

    final headers = {'Content-Type': 'application/json'};

    final body = json.encode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'You are Agrow AI, an expert agricultural advisor powered by Gemini 2.0. Provide helpful, practical farming advice. Focus on crop management, soil health, pest control, weather considerations, and sustainable farming practices. Keep responses concise but informative, suitable for farmers of all experience levels. ${imageFile != null ? 'Analyze the provided crop image and ' : ''}User question: $message',
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 500,
      },
    });

    final response = await http.post(
      Uri.parse('$apiUrl?key=$_apiKey'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        return data['candidates'][0]['content']['parts'][0]['text'].trim();
      } else {
        throw Exception('No response generated from Gemini');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key. Please check your Gemini API key.');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded. Please try again later.');
    } else {
      throw Exception(
        'Failed to get AI response. Status: ${response.statusCode}',
      );
    }
  }

  Future<void> _saveChatToStorage(String userMessage, String aiResponse) async {
    try {
      await StorageService.saveChatMessage(
        message: userMessage,
        response: aiResponse,
        isUser: false,
      );
    } catch (e) {
      print('Failed to save chat: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppTheme.primaryGreen,
              ),
              title: const Text('Camera'),
              subtitle: const Text('Take a photo of your crop'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppTheme.primaryBlue,
              ),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from your photos'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini 2.0 AI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppTheme.primaryGreen,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Powered by Google Gemini 2.0 Flash',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your AI agricultural advisor is ready to help with expert farming guidance, crop management, and sustainable agriculture practices.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.lightGreen),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successGreen,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API configured and ready!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  /// Initialize location-based voice functionality
  Future<void> _initLocationBasedVoice() async {
    try {
      // Determine locale from location
      final (cc, st) = await _getRegion();
      final sttLocale = _pickLocaleForRegion(cc, st); // e.g., hi_IN
      final ttsLocale = _toBcp47(sttLocale); // e.g., hi-IN
      _chosenLocale = sttLocale;
      _chosenBcp47 = ttsLocale;
      _regionLabel = '$st, $cc';

      // Init STT
      _speech = stt.SpeechToText();
      _speechEnabled = await _speech.initialize(
        onStatus: (s) => debugPrint('STT status: $s'),
        onError: (e) => debugPrint('STT error: $e'),
      );

      // Init TTS with selected locale
      _tts = FlutterTts();
      await _tts.setLanguage(_chosenBcp47);
      await _tts.setSpeechRate(
        0.25,
      ); // Much slower speech rate for better comprehension
      await _tts.setPitch(1.0);
      _ttsEnabled = true;
      _localeReady = true;
    } catch (e) {
      // On failure, fallback to device locale
      final dev = ui.PlatformDispatcher.instance.locale;
      _chosenLocale = '${dev.languageCode}_${dev.countryCode ?? 'IN'}';
      _chosenBcp47 = _toBcp47(_chosenLocale);
      _regionLabel = 'Fallback to device locale';

      _speech = stt.SpeechToText();
      _speechEnabled = await _speech.initialize();
      _tts = FlutterTts();
      await _tts.setLanguage(_chosenBcp47);
      await _tts.setSpeechRate(
        0.4,
      ); // Much slower speech rate for fallback mode too
      _ttsEnabled = true;
      _localeReady = true;
    }
    if (mounted) setState(() {});
  }

  /// Start listening to speech input with location-based locale
  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _lastWords = '';
    await _speech.listen(
      localeId: _chosenLocale, // Use location-based locale
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      onResult: (result) {
        setState(() {
          if (result.finalResult) {
            _lastWords = result.recognizedWords;
            _messageController.text = _lastWords;
          } else {
            // Show partial results in real-time
            _messageController.text = result.recognizedWords;
          }
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );

    setState(() {
      _isListening = true;
    });
  }

  /// Stop listening to speech input
  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  /// Toggle speech listening
  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  /// Speak text using TTS with location-based locale
  Future<void> _speakText(String text) async {
    if (!_ttsEnabled || !_localeReady) return;

    setState(() {
      _isSpeaking = true;
    });

    try {
      await _tts.setLanguage(_chosenBcp47);
      await _tts.setSpeechRate(0.4); // Ensure much slower speech rate
      await _tts.speak(text);

      // Wait for TTS to complete
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isSpeaking = false;
      });
      debugPrint('TTS error: $e');
    }
  }

  /// Stop current TTS playback
  Future<void> _stopSpeaking() async {
    await _tts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        elevation: 4,
        shadowColor: AppTheme.primaryGreen.withOpacity(0.2),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agrow AI Assistant',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    _localeReady
                        ? 'Voice: $_regionLabel ($_chosenLocale)'
                        : 'Powered by Gemini 2.0 • Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // TTS control button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _isSpeaking
                      ? Colors.red.withOpacity(0.1)
                      : AppTheme.primaryBlue.withOpacity(0.1),
                  _isSpeaking
                      ? Colors.red.withOpacity(0.05)
                      : AppTheme.secondaryBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isSpeaking
                    ? Colors.red.withOpacity(0.3)
                    : AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                _isSpeaking ? Icons.volume_off : Icons.volume_up,
                color: _isSpeaking ? Colors.red : AppTheme.primaryBlue,
                size: 20,
              ),
              onPressed: _isSpeaking ? _stopSpeaking : null,
              tooltip: _isSpeaking ? 'Stop reading' : 'Voice reading enabled',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.1),
                  AppTheme.secondaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              onPressed: _showApiKeyDialog,
              tooltip: 'Settings & Info',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome header (shows only when no messages)
          if (_messages.isEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.08),
                    AppTheme.secondaryGreen.withOpacity(0.03),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.secondaryGreen,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.eco, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Agrow AI Assistant!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your intelligent farming companion powered by AI. Get expert advice on crops, soil health, weather insights, pest management, and more.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Quick Start:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildSuggestionChip(
                        '🌾 Crop diseases',
                        'What are common wheat diseases?',
                      ),
                      _buildSuggestionChip(
                        '🌱 Soil health',
                        'How to improve soil fertility?',
                      ),
                      _buildSuggestionChip(
                        '🌦️ Weather advice',
                        'Best planting time for corn?',
                      ),
                      _buildSuggestionChip(
                        '🐛 Pest control',
                        'Natural pest control methods',
                      ),
                      _buildSuggestionChip(
                        '📸 Photo analysis',
                        'Take a photo to analyze',
                      ),
                      _buildSuggestionChip(
                        '🎤 Voice input',
                        'Try voice input by tapping the microphone',
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
                  ),
          ),
          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.secondaryGreen,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(21),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.eco, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[50]!, Colors.grey[100]!],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'AI is analyzing and preparing response...',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Selected image preview
                if (_selectedImage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            _selectedImage!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Crop image selected for analysis',
                            style: TextStyle(color: AppTheme.primaryGreen),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                // Input row
                Row(
                  children: [
                    // Camera button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryGreen.withOpacity(0.1),
                            AppTheme.secondaryGreen.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(
                          Icons.camera_alt,
                          color: AppTheme.primaryGreen,
                        ),
                        tooltip: 'Add crop photo for analysis',
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Microphone button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isListening
                              ? [
                                  Colors.red.withOpacity(0.2),
                                  Colors.red.withOpacity(0.1),
                                ]
                              : [
                                  AppTheme.primaryBlue.withOpacity(0.1),
                                  AppTheme.secondaryBlue.withOpacity(0.05),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _isListening
                              ? Colors.red.withOpacity(0.4)
                              : AppTheme.primaryBlue.withOpacity(0.3),
                          width: _isListening ? 2 : 1,
                        ),
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: IconButton(
                        onPressed: _speechEnabled ? _toggleListening : null,
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening
                              ? Colors.red
                              : (_speechEnabled
                                    ? AppTheme.primaryBlue
                                    : Colors.grey),
                        ),
                        tooltip: _isListening
                            ? 'Stop voice input'
                            : 'Start voice input',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _isListening
                                ? 'Listening... Speak your farming question'
                                : 'Ask me about crops, soil, weather, pests...',
                            hintStyle: TextStyle(
                              color: _isListening
                                  ? Colors.red[400]
                                  : Colors.grey[500],
                              fontSize: 16,
                              fontStyle: _isListening
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? Colors.red.withOpacity(0.1)
                                    : AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _isListening
                                    ? Icons.mic
                                    : Icons.chat_bubble_outline,
                                color: _isListening
                                    ? Colors.red
                                    : AppTheme.primaryGreen,
                                size: 20,
                              ),
                            ),
                            suffixIcon: _isListening
                                ? Container(
                                    margin: const EdgeInsets.all(8),
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.red,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: AppTheme.primaryGreen,
                          cursorWidth: 2,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.secondaryGreen,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Send message',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: message.isUser
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryGreen,
                                AppTheme.secondaryGreen,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Colors.white, Colors.grey[50]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(22),
                        topRight: const Radius.circular(22),
                        bottomLeft: Radius.circular(message.isUser ? 22 : 6),
                        bottomRight: Radius.circular(message.isUser ? 6 : 22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: message.isUser
                              ? AppTheme.primaryGreen.withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: message.isUser
                          ? null
                          : Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display image if available
                        if (message.imageFile != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                message.imageFile!,
                                width: 200,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                        // Display text
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: TextStyle(
                              color: message.isUser
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (message.isUser) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: AppTheme.primaryGreen,
                          ),
                        ],
                        // Add speaker button for AI messages
                        if (!message.isUser && _ttsEnabled && _localeReady) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _speakText(message.text),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.volume_up,
                                size: 14,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 16),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, [String? fullMessage]) {
    return GestureDetector(
      onTap: () {
        _messageController.text =
            fullMessage ?? text.replaceAll(RegExp(r'[🌾🌱🌦️🐛📸💧]\s*'), '');
        _sendMessage();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppTheme.primaryGreen.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final File? imageFile;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageFile,
  });
}

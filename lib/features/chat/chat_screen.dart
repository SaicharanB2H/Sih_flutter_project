import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/services/storage_service.dart';
import '../../shared/theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            'Hello! I\'m your Agrow AI assistant powered by Gemini 2.0! How can I help you with your farming today? You can also send me photos of your crops for analysis and suggestions!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
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
                    'Powered by Gemini 2.0 • Online',
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
                        '💧 Irrigation',
                        'Water management tips',
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
                    const SizedBox(width: 12),
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
                            hintText:
                                'Ask me about crops, soil, weather, pests...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
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
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                            ),
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
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
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

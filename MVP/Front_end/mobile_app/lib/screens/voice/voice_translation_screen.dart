import 'package:flutter/material.dart';
import '../../models/poi_translation.dart';
import '../../services/voice/voice_translation_service.dart';

/// Screen 11: 语音翻译全屏页面
///
/// 规范来自 SCREEN_SPECIFICATIONS_v2.md
/// - 沉浸式双向语音翻译
/// - Direction toggle: EN → 中 ⇄ 中 → EN
/// - 对话历史记录
/// - 快捷短语
/// - 80×80px 大麦克风按钮
class VoiceTranslationScreen extends StatefulWidget {
  const VoiceTranslationScreen({super.key});

  @override
  State<VoiceTranslationScreen> createState() => _VoiceTranslationScreenState();
}

class _VoiceTranslationScreenState extends State<VoiceTranslationScreen>
    with SingleTickerProviderStateMixin {

  final VoiceTranslationService _service = VoiceTranslationService();
  late AnimationController _rippleController;

  TranslationDirection _direction = TranslationDirection.foreignToChinese;
  AppLanguage _selectedLanguage = AppLanguage.english;

  // 快捷短语
  final Map<AppLanguage, List<String>> _quickPhrases = {
    AppLanguage.english: [
      'How much?',
      'Where is...?',
      'Help!',
      'Thank you',
      'No, thanks',
    ],
    AppLanguage.french: [
      'Combien?',
      'Où est...?',
      'Au secours!',
      'Merci',
      'Non merci',
    ],
    AppLanguage.spanish: [
      '¿Cuánto cuesta?',
      '¿Dónde está...?',
      '¡Ayuda!',
      'Gracias',
      'No, gracias',
    ],
  };

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _service.addListener(_onServiceStateChanged);
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _service.removeListener(_onServiceStateChanged);
    super.dispose();
  }

  void _onServiceStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleMicPress() async {
    if (_service.state == VoiceServiceState.idle) {
      try {
        await _service.startRecording();
      } catch (e) {
        _showError('麦克风权限未授权');
      }
    }
  }

  Future<void> _handleMicRelease() async {
    if (_service.state == VoiceServiceState.recording) {
      await _service.stopAndTranslate(
        direction: _direction,
        foreignLanguage: _selectedLanguage,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Voice Translation'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Direction Toggle
            _buildDirectionToggle(),

            const SizedBox(height: 16),

            // Language Selector
            _buildLanguageSelector(),

            const SizedBox(height: 24),

            // Conversation History
            Expanded(
              child: _buildConversationHistory(),
            ),

            // Quick Phrases
            _buildQuickPhrases(),

            const SizedBox(height: 24),

            // Mic Button
            _buildMicButton(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDirectionPill(
            label: '${_getLanguageCode(_selectedLanguage)} → 中',
            isActive: _direction == TranslationDirection.foreignToChinese,
            onTap: () {
              setState(() {
                _direction = TranslationDirection.foreignToChinese;
              });
            },
          ),
          const SizedBox(width: 16),
          const Icon(Icons.swap_horiz, color: Color(0xFF10B981)),
          const SizedBox(width: 16),
          _buildDirectionPill(
            label: '中 → ${_getLanguageCode(_selectedLanguage)}',
            isActive: _direction == TranslationDirection.chineseToForeign,
            onTap: () {
              setState(() {
                _direction = TranslationDirection.chineseToForeign;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'Language:',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 12),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppLanguage>(
                value: _selectedLanguage,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                items: const [
                  DropdownMenuItem(
                    value: AppLanguage.english,
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: AppLanguage.french,
                    child: Text('Français'),
                  ),
                  DropdownMenuItem(
                    value: AppLanguage.spanish,
                    child: Text('Español'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedLanguage = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationHistory() {
    final history = _service.history;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tap and hold the mic button\nto start translating',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final result = history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Original text bubble
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You said:',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.originalText,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${result.processingTime.inMilliseconds}ms · ${_getLanguageCode(result.foreignLanguage)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Translation bubble
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5), // Jade 100
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Translation:',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.translatedText,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // TODO: Replay TTS
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volume_up, size: 16, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text(
                              'Tap to replay',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickPhrases() {
    final phrases = _quickPhrases[_selectedLanguage] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Quick Phrases:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: phrases.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    // TODO: Auto-translate and play phrase
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      phrases[index],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMicButton() {
    final state = _service.state;

    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => _handleMicPress(),
          onTapUp: (_) => _handleMicRelease(),
          onTapCancel: _handleMicRelease,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: state == VoiceServiceState.idle
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFFFF6B35)],
                    )
                  : null,
              color: state == VoiceServiceState.idle
                  ? null
                  : state == VoiceServiceState.recording
                      ? Colors.red
                      : state == VoiceServiceState.processing
                          ? const Color(0xFFFF6B35)
                          : state == VoiceServiceState.playing
                              ? const Color(0xFF4CAF50)
                              : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (state == VoiceServiceState.idle
                          ? const Color(0xFF10B981)
                          : state == VoiceServiceState.recording
                              ? Colors.red
                              : const Color(0xFFFF6B35))
                      .withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: state == VoiceServiceState.processing
                ? const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : Icon(
                    state == VoiceServiceState.playing
                        ? Icons.volume_up
                        : Icons.mic,
                    color: Colors.white,
                    size: 36,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _getStateLabel(state),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  String _getLanguageCode(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'EN';
      case AppLanguage.french:
        return 'FR';
      case AppLanguage.spanish:
        return 'ES';
    }
  }

  String _getStateLabel(VoiceServiceState state) {
    switch (state) {
      case VoiceServiceState.idle:
        return 'Hold to speak';
      case VoiceServiceState.recording:
        return 'Listening...';
      case VoiceServiceState.processing:
        return 'Translating...';
      case VoiceServiceState.playing:
        return 'Playing...';
      case VoiceServiceState.error:
        return 'Error, try again';
    }
  }
}

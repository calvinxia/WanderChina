import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/poi_translation.dart';
import '../../services/voice/voice_translation_service.dart';

/// Screen 11: 语音翻译全屏页面
///
/// 规范来自 FLUTTER_UI_REDESIGN_INSTRUCTIONS.md Step UI-6
/// - 沉浸式双向语音翻译
/// - Direction toggle: EN → 中 ⇄ 中 → EN (可切换)
/// - 对话历史记录
/// - 快捷短语（点击自动翻译+播放）
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
        title: Text(
          'Voice Translation',
          style: AppTextStyles.h4(color: AppColors.gray900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
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
          // Swap button to toggle direction
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            color: AppColors.jade500,
            onPressed: () {
              setState(() {
                _direction = _direction == TranslationDirection.foreignToChinese
                    ? TranslationDirection.chineseToForeign
                    : TranslationDirection.foreignToChinese;
              });
            },
            tooltip: 'Swap direction',
          ),
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
          color: isActive ? AppColors.jade500 : AppColors.gray100,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.gray600,
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
          Text(
            'Language:',
            style: AppTextStyles.body(color: AppColors.gray600),
          ),
          const SizedBox(width: 12),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppLanguage>(
                value: _selectedLanguage,
                icon: Icon(Icons.arrow_drop_down, size: 20, color: AppColors.gray600),
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
            Icon(Icons.mic_none, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              'Tap and hold the mic button\nto start translating',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: AppColors.gray500),
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
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You said:',
                        style: AppTextStyles.caption(color: AppColors.gray600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.originalText,
                        style: AppTextStyles.body(color: AppColors.gray900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${result.processingTime.inMilliseconds}ms · ${_getLanguageCode(result.foreignLanguage)}',
                        style: AppTextStyles.caption(color: AppColors.gray400),
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
                    color: AppColors.jade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Translation:',
                        style: AppTextStyles.caption(color: AppColors.jade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.translatedText,
                        style: AppTextStyles.body(color: AppColors.gray900),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          // Replay TTS for translated text
                          final targetLang = result.direction == TranslationDirection.foreignToChinese
                              ? 'zh'
                              : (result.foreignLanguage == AppLanguage.english
                                  ? 'en'
                                  : result.foreignLanguage == AppLanguage.french
                                      ? 'fr'
                                      : 'es');
                          await _service.replayTTS(result.translatedText, targetLang);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volume_up, size: 16, color: AppColors.jade700),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to replay',
                              style: AppTextStyles.caption(color: AppColors.jade700),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Quick Phrases:',
            style: AppTextStyles.caption(color: AppColors.gray600).copyWith(
              fontWeight: FontWeight.w600,
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
                  onTap: () async {
                    // Auto-translate and play phrase
                    await _service.translateQuickPhrase(
                      phrase: phrases[index],
                      direction: _direction,
                      foreignLanguage: _selectedLanguage,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.gray300),
                    ),
                    child: Text(
                      phrases[index],
                      style: AppTextStyles.caption(color: AppColors.gray700),
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
                      colors: [AppColors.jade500, Color(0xFFE8723A)], // Jade 500 → #E8723A
                    )
                  : null,
              color: state == VoiceServiceState.idle
                  ? null
                  : state == VoiceServiceState.recording
                      ? AppColors.error500
                      : state == VoiceServiceState.processing
                          ? const Color(0xFFE8723A)
                          : state == VoiceServiceState.playing
                              ? const Color(0xFF4CAF50)
                              : AppColors.gray400,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (state == VoiceServiceState.idle
                          ? AppColors.jade500
                          : state == VoiceServiceState.recording
                              ? AppColors.error500
                              : const Color(0xFFE8723A))
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
          style: AppTextStyles.caption(color: AppColors.gray600),
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

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/poi_translation.dart';
import '../../services/voice/voice_translation_service.dart';
import '../../core/theme/city_theme.dart';
import '../../widgets/common/city_background.dart';
import '../main/main_screen.dart';
import '../../utils/quota_helper.dart';
import '../../services/backend/auth_service.dart';
import '../../widgets/soft_login_sheet.dart';

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
  final TextEditingController _textController = TextEditingController();

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
    _textController.dispose();
    _service.removeListener(_onServiceStateChanged);
    super.dispose();
  }

  void _onServiceStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleMicPress() async {
    debugPrint('🎙️ Long press START - state: ${_service.state}');

    // 软登录检查：匿名用户弹注册引导
    final mainState = MainScreen.globalKey.currentState;
    final cityTheme = mainState?.cityTheme ?? CityTheme.defaultTheme;
    if (!await requireLogin(context, 'voice_translate', theme: cityTheme)) return;
    // Quota check
    if (!await requireQuotaCheck(
      context,
      'voice_translate',
      cityTheme,
      userId: AuthService.currentUserId,
    )) return;

    if (_service.state == VoiceServiceState.idle) {
      try {
        await _service.startRecording();
        debugPrint('🎙️ Recording started successfully');
      } catch (e) {
        debugPrint('⚠️ Recording failed: $e');
        _showError('麦克风权限未授权');
      }
    } else {
      debugPrint('⚠️ Cannot start recording, current state: ${_service.state}');
    }
  }

  Future<void> _handleMicRelease() async {
    debugPrint('🎙️ Long press END - state: ${_service.state}');
    if (_service.state == VoiceServiceState.recording) {
      debugPrint('🎙️ Stopping recording and translating...');
      final result = await _service.stopAndTranslate(
        direction: _direction,
        foreignLanguage: _selectedLanguage,
      );
      if (result == null) {
        debugPrint('⚠️ Translation failed or returned null');
      } else {
        debugPrint('✅ Translation completed: ${result.originalText} → ${result.translatedText}');
      }
    } else {
      debugPrint('⚠️ Cannot stop recording, current state: ${_service.state}');
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
    final mainState = MainScreen.globalKey.currentState;
    final cityTheme = mainState?.cityTheme ?? CityTheme.defaultTheme;

    return CityBackground(
      theme: cityTheme,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
          title: Text(
            'Voice Translation',
            style: AppTextStyles.h4(color: AppColors.gray900),
          ),
          backgroundColor: Colors.transparent,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 固定顶部区域
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),

                // Direction Toggle
                _buildDirectionToggle(),

                const SizedBox(height: 24),
              ],
            ),

            // Conversation History（可滚动，占据剩余空间） — 键盘弹出时隐藏
            if (MediaQuery.of(context).viewInsets.bottom == 0)
              Expanded(
                child: _buildConversationHistory(),
              )
            else
              const Spacer(),

            // 底部操作区（键盘弹出时自动上移）
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Phrases
                _buildQuickPhrases(),

                const SizedBox(height: 16),

                // Text Input
                _buildTextInput(),

                const SizedBox(height: 16),

                // Mic Button
                _buildMicButton(),

                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildDirectionToggle() {
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    final cityTheme = mainState?.cityTheme ?? CityTheme.defaultTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDirectionPill(
            label: '${_getLanguageCode(_selectedLanguage)} → CN',
            isActive: _direction == TranslationDirection.foreignToChinese,
            cityTheme: cityTheme,
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
            color: cityTheme.pillActiveColor,
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
            label: 'CN → ${_getLanguageCode(_selectedLanguage)}',
            isActive: _direction == TranslationDirection.chineseToForeign,
            cityTheme: cityTheme,
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
    required CityTheme cityTheme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? cityTheme.pillActiveColor : Colors.white.withOpacity(0.25),
          border: Border.all(
            color: isActive ? cityTheme.pillActiveColor : Colors.white.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : cityTheme.pillActiveColor,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationHistory() {
    final history = _service.history;

    if (history.isEmpty) {
      final mainState = context.findAncestorStateOfType<MainScreenState>();
      final cityTheme = mainState?.cityTheme ?? CityTheme.defaultTheme;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_none, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              'Tap and hold the mic button\nto start translating',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: cityTheme.primaryTextColor.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: true, // 新消息在底部
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: history.length,
      itemBuilder: (context, index) {
        // reverse=true时，索引也要反转
        final result = history[history.length - 1 - index];
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
                            const Icon(Icons.volume_up, size: 16, color: AppColors.jade700),
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
                    debugPrint('📝 Quick Phrase tapped: ${phrases[index]}');
                    final result = await _service.translateQuickPhrase(
                      phrase: phrases[index],
                      direction: _direction,
                      foreignLanguage: _selectedLanguage,
                    );
                    if (result != null) {
                      debugPrint('✅ Quick Phrase translated: ${result.originalText} → ${result.translatedText}');
                    } else {
                      debugPrint('⚠️ Quick Phrase translation failed');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
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

  Widget _buildTextInput() {
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    final cityTheme = mainState?.cityTheme ?? CityTheme.defaultTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppColors.gray400, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: _sendTextMessage,
              ),
            ),
            GestureDetector(
              onTap: () => _sendTextMessage(_textController.text),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: cityTheme.pillActiveColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    FocusScope.of(context).unfocus(); // 收键盘
    _textController.clear();

    final result = await _service.translateQuickPhrase(
      phrase: text.trim(),
      direction: _direction,
      foreignLanguage: _selectedLanguage,
    );

    if (result != null && mounted) {
      debugPrint('✅ Text message translated: ${result.originalText} → ${result.translatedText}');
    } else {
      debugPrint('⚠️ Text message translation failed');
    }
  }

  Widget _buildMicButton() {
    final state = _service.state;

    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => _handleMicPress(),
          onLongPressEnd: (_) => _handleMicRelease(),
          onLongPressCancel: _handleMicRelease,
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

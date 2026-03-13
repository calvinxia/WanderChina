import 'package:flutter/material.dart';
import '../../models/poi_translation.dart';
import '../../services/voice/voice_translation_service.dart';

class VoiceTranslationOverlay extends StatefulWidget {
  final AppLanguage language;

  const VoiceTranslationOverlay({super.key, required this.language});

  @override
  State<VoiceTranslationOverlay> createState() =>
      _VoiceTranslationOverlayState();
}

class _VoiceTranslationOverlayState extends State<VoiceTranslationOverlay>
    with SingleTickerProviderStateMixin {

  final VoiceTranslationService _svc = VoiceTranslationService();
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  TranslationDirection     _direction    = TranslationDirection.foreignToChinese;
  VoiceTranslationResult?  _latestResult;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _svc.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _onMicDown() async {
    try {
      await _svc.startRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone permission required'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _onMicUp() async {
    if (_svc.state != VoiceServiceState.recording) return;
    final result = await _svc.stopAndTranslate(
      direction:       _direction,
      foreignLanguage: widget.language,
    );
    if (result != null && mounted) {
      setState(() => _latestResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state      = _svc.state;
    final bottomPad  = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right:  16,
      bottom: bottomPad + 90,
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize:        MainAxisSize.min,
        children: [
          // 翻译结果气泡
          if (_latestResult != null) ...[
            _ResultBubble(result: _latestResult!),
            const SizedBox(height: 8),
          ],

          // 方向切换
          _DirectionChip(
            direction: _direction,
            language:  widget.language,
            onTap: () => setState(() {
              _direction = _direction == TranslationDirection.foreignToChinese
                  ? TranslationDirection.chineseToForeign
                  : TranslationDirection.foreignToChinese;
              _latestResult = null;
            }),
          ),
          const SizedBox(height: 10),

          // 录音按钮
          _MicButton(
            state:     state,
            pulse:     _pulseAnim,
            onDown:    _onMicDown,
            onUp:      _onMicUp,
            onCancel:  _svc.cancelRecording,
            onStop:    _svc.stopPlaying,
          ),

          // 提示文字
          const SizedBox(height: 4),
          _HintText(state: state, direction: _direction),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _svc.removeListener(_onStateChange);
    super.dispose();
  }
}

// ─── 子组件 ───────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  final VoiceServiceState state;
  final Animation<double> pulse;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final VoidCallback onCancel;
  final VoidCallback onStop;

  const _MicButton({
    required this.state,
    required this.pulse,
    required this.onDown,
    required this.onUp,
    required this.onCancel,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    // 播放中 → 点击停止
    if (state == VoiceServiceState.playing) {
      return GestureDetector(
        onTap: onStop,
        child: _circle(const Color(0xFF4CAF50), Icons.volume_up),
      );
    }

    // 处理中 → 禁用，显示loading
    if (state == VoiceServiceState.processing) {
      return _circle(Colors.orange, null, loading: true);
    }

    // 录音中 → 脉冲动画
    if (state == VoiceServiceState.recording) {
      return GestureDetector(
        onTapUp:    (_) => onUp(),
        onTapCancel: onCancel,
        child: AnimatedBuilder(
          animation: pulse,
          builder:  (_, child) => Transform.scale(
            scale: pulse.value,
            child: child,
          ),
          child: _circle(Colors.red, Icons.mic),
        ),
      );
    }

    // 待机 → 长按触发
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp:   (_) => onUp(),
      onTapCancel: onCancel,
      child: _circle(const Color(0xFFFF6B35), Icons.mic),
    );
  }

  Widget _circle(Color color, IconData? icon, {bool loading = false}) {
    return Container(
      width:  64,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius:   12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: loading
          ? const Center(
              child: SizedBox(
                width:  28,
                height: 28,
                child:  CircularProgressIndicator(
                  color:       Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _ResultBubble extends StatelessWidget {
  final VoiceTranslationResult result;
  const _ResultBubble({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:        MainAxisSize.min,
        children: [
          Text(
            result.originalText,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const Divider(height: 8),
          Text(
            result.translatedText,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${result.processingTime.inMilliseconds}ms',
            style: TextStyle(fontSize: 9, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final TranslationDirection direction;
  final AppLanguage          language;
  final VoidCallback         onTap;

  const _DirectionChip({
    required this.direction,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final langCode = switch (language) {
      AppLanguage.english  => 'EN',
      AppLanguage.french   => 'FR',
      AppLanguage.spanish  => 'ES',
    };
    final label = direction == TranslationDirection.foreignToChinese
        ? '$langCode → 中'
        : '中 → $langCode';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 6),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.swap_horiz, size: 14, color: Color(0xFFFF6B35)),
          ],
        ),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final VoiceServiceState    state;
  final TranslationDirection direction;
  const _HintText({required this.state, required this.direction});

  @override
  Widget build(BuildContext context) {
    final text = switch (state) {
      VoiceServiceState.idle       => 'Tap & hold to speak',
      VoiceServiceState.recording  => 'Listening...',
      VoiceServiceState.processing => 'Translating...',
      VoiceServiceState.playing    => 'Tap to stop',
      VoiceServiceState.error      => 'Error, try again',
    };
    return Text(
      text,
      style: const TextStyle(
        fontSize:  10,
        color:     Colors.white,
        shadows:   [Shadow(color: Colors.black54, blurRadius: 4)],
      ),
    );
  }
}

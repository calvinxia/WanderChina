import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 深链服务 — Alipay + DiDi
/// 产品决策: 只集成 Alipay + DiDi。不集成大众点评/美团/携程（无英文支持）。
class DeeplinkService {

  /// 打开 Alipay 扫一扫（线下消费扫码支付）
  /// 返回 true = 成功跳转，false = Alipay 未安装
  static Future<bool> openAlipayScanner() async {
    const url = 'alipays://platformapi/startapp?appId=10000007';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Open Alipay scanner failed: $e');
    }
    return false;
  }

  /// 打开 DiDi 打车（独立 App）
  /// 复制目的地到剪贴板，方便用户粘贴
  /// 返回 true = 成功跳转，false = DiDi 未安装
  static Future<bool> openDidi(String destName) async {
    await Clipboard.setData(ClipboardData(text: destName));

    const url = 'diditaxi://';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Open DiDi failed: $e');
    }
    return false;
  }

  /// 检查 Alipay 是否安装
  static Future<bool> isAlipayInstalled() async {
    try {
      return await canLaunchUrl(Uri.parse('alipays://'));
    } catch (_) {
      return false;
    }
  }
}

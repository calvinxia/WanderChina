# 调试专用 paywall 入口 — 设计记录

> **日期:** 2026-10-18
> **版本:** v1.2.1(build 25)
> **状态:** ✅ 已实现(2026-10-18),只读确认已完成,结论见第 2 节
> **关联:** `V1.2.1_实现规格_v3.2.md` 第五节 4.5「购买前须注册」;回归清单第 7、8 项

---

## 1. 要解决的问题

v1.2.1 新增了购买门控:未注册用户在 paywall 点购买时,先弹软登录,成功后回到 paywall 由用户再次确认。这条路径必须在上架前实测。

但测试它需要 paywall 弹出来,而当前:

- `paywall_enabled` 在线上**双端关闭**(PMF 阶段的既定策略)
- 该开关是**全局的**:在线上打开,所有真实用户都会立刻看到付费墙
- 项目**没有独立的测试环境**,数据库与云函数只有一套

所以**不能通过修改线上 flag 来测门控**。需要一个只在开发者本机生效、对线上用户零影响的入口。

---

## 2. 关键事实:paywall 不只由前端决定

`check_user_quota` 的线上日志中出现过:

```
{"allowed": true, "reason": "paywall_disabled", "trigger_paywall": false}
```

即**后端也在读 paywall 开关**,并由它决定是否 `trigger_paywall`。若前端仅在收到 `trigger_paywall: true` 时才弹出 paywall,那么只在前端覆盖 `paywallEnabled` 无效——后端仍会告诉前端"不用弹"。

**结论:覆盖点应放在"弹出 `PaywallDialog`"这一步,而不是 flag 的取值。** 要测的门控逻辑本身就位于 `paywall_dialog.dart` 的 `_handlePurchase()` 中,只要能打开弹窗,就能完整覆盖"匿名点购买 → 弹软登录 → 回到 paywall 再确认"的路径。

### ✅ 确认结果(2026-10-18)

`PaywallDialog` 有**两条互相独立的触发路径**:

| 路径 | 触发条件 | 调用点 |
|---|---|---|
| **额度门控**(主路径) | 后端 `check_user_quota` 返回 `allowed = false` | `quota_helper.dart:38`,由 `requireQuotaCheck()` 统一调用 |
| **Profile 订阅卡片**(次路径) | `FeatureFlagsService.paywallEnabled = true` 时卡片可见,用户点击 | `profile_screen.dart:869` |

- **`FeatureFlagsService.paywallEnabled` 不参与额度门控**,只控制 Profile 订阅卡片的显隐(fail-closed,默认隐藏)
- 额度门控完全由后端返回值驱动;paywall 关闭时后端返回 `allowed: true, reason: "paywall_disabled"`,前端因此不弹窗
- `requireQuotaCheck()` 的三处调用点:`planner_home_screen.dart:796`(新建行程)、`itinerary_detail_screen.dart:636`(AI 编辑)、`voice_translation_screen.dart:101`(语音翻译)

**这印证了第 2 节的推断**:只在前端覆盖 `paywallEnabled` 无法让额度门控弹出 paywall。

**门控对两条路径都有效。** 购买门控写在 `PaywallDialog._handlePurchase()` 内,无论从哪条路径打开弹窗,点购买时都会先检查注册状态。

---

## 3. 设计:两道开关同时成立才生效

```dart
// DEBUG-ONLY: 用于测试购买门控,release 构建不生效
const bool kForcePaywall = bool.fromEnvironment('FORCE_PAYWALL');

// 在行程额度检查的入口处:
if (kDebugMode && kForcePaywall) {
  // 直接弹出 PaywallDialog,跳过后端额度判断
}
```

| 开关 | 性质 | 作用 |
|---|---|---|
| `kDebugMode` | Flutter 编译期常量,release 构建中恒为 `false` | 该分支在 release 构建中被编译器剪除,**不会进入上架包** |
| `FORCE_PAYWALL` | 编译期定义,须启动时显式传入 | 平时跑 debug 不会意外弹出 paywall |

**为什么不只用 `kDebugMode`:** 那样每次调试都会弹 paywall,干扰其他功能的开发与测试。

**为什么不只用 `FORCE_PAYWALL`:** 若有人误在 release 构建时传入该定义,门控测试代码会进入上架包。`kDebugMode` 是这层误操作的兜底。

---

## 4. 明确不做的事

| 不做 | 原因 |
|---|---|
| 修改线上 `paywall_enabled` | 全局开关,会影响所有真实用户 |
| 修改 `FeatureFlagsService` 的服务端取值逻辑 | 让 flag 的语义保持单一:它只反映后端真实状态 |
| 修改后端 | 后端无需感知任何调试状态 |
| 用账号白名单 / 测试用户标记 | 需要后端配合,范围超出本次;且同一套数据库下易误伤 |

---

## 5. 实现与使用方法

**实现位置:** `lib/utils/quota_helper.dart`

| 行 | 内容 |
|---|---|
| 1 | `import 'package:flutter/foundation.dart';` |
| 9 | `const bool kForcePaywall = bool.fromEnvironment('FORCE_PAYWALL');` |
| 24–27 | `kDebugMode && kForcePaywall` 时直接弹出 `PaywallDialog`,跳过后端额度判断 |

**启动命令:**

```bash
flutter run --dart-define-from-file=.env --dart-define=FORCE_PAYWALL=true
```

⚠️ **`--dart-define-from-file=.env` 不能省。** 后端地址等配置都由它注入;只传 `FORCE_PAYWALL` 而漏掉它,app 会拿不到任何接口地址。

⚠️ **开启后,三个调用点都会直接弹 paywall**(新建行程、AI 编辑、语音翻译)。这是预期行为;测完其他功能时去掉 `FORCE_PAYWALL` 重新启动即可。

用于回归清单:

- **第 7 项** 匿名点购买 → 弹软登录,未直接扣款;登录后回到 paywall,需再次点击才购买;取消则停留在 paywall
- **第 8 项** 已注册用户 IAP 沙盒购买 → 流程与改动前一致(iOS)

---

## 5.1 实测补充(2026-10-19,回归第 7 项)

**三个额度入口都是先 `requireLogin`、后额度检查。** 实测:匿名点生成行程 → 先弹软登录 → 登录后才弹 paywall。Voice 页(`voice_translation_screen.dart:99` 先于 `:101`)与 AI 编辑同理。

**结论:**
- 在当前界面上,**匿名用户无法到达 paywall**;本入口(位于额度检查内)也只会在登录之后生效
- 步骤 0 第 1 项"匿名可经 paywall 购买"的结论偏悲观:当时只看了 `quota_helper → showPaywallDialog`,未看到调用方之前的登录门控
- `PaywallDialog._handlePurchase()` 中的购买门控**保留为纵深防御**:若将来新增不经登录即可打开 paywall 的入口,它能兜住
- "匿名点购买 → 弹软登录"这一分支在当前界面不可达,**以代码审查为准**;如需实测,须另加一个先于登录门控的调试入口

---

## 6. 只读确认 —— ✅ 已完成

结论已写入第 2 节,实现位置见第 5 节。

---

## 7. 保留策略

- **保留这段代码。** 开墙前调试 paywall、调整阈值、验证文案时仍会用到
- 每次发版前确认:release 构建中该入口不生效(以 release 包实测为准,不仅看代码)
- 若将来项目有了独立测试环境,可评估改为服务端的测试账号机制,届时移除本入口

---

## 8. 变更记录

| 日期 | 变更 |
|---|---|
| 2026-10-18 | 初稿:问题、关键事实、两道开关设计、不做的事、使用方法、待确认项 |
| 2026-10-18 | 补入触发机制确认结果与实现位置;注明启动命令须带 `.env` |
| 2026-10-19 | 补入实测:三个额度入口均先登录后检查额度,匿名用户在当前界面无法到达 paywall |

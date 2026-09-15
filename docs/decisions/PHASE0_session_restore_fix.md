# Phase 0 · 会话恢复链路修复 — 执行指令

> **日期:** 2026-09-14
> **分支:** `fix/session-restore`(基于 `cb1c56e`)
> **性质:** 🔴 **行为修正,非重构** —— 不含任何 Riverpod 相关改动
> **前置:** 改名版 v1.1.0+23 双端已上线一个月;本轮全部工作已 commit 并推送
> **关联:** `RIVERPOD_MIGRATION_GUIDE_v2.md` §2(本文件是该节的执行版)

---

## 一、问题来源与证据链

### 1.1 触发事件

Sentry 面包屑(2026-09-14 10:12–10:14 UTC / 18:12–18:14 北京时间),用户 `bb536edd-8f64-4ff9-b058-07f7a12c10ff`:

```
10:12:16  app 进入前台
10:12:18  高德日志上传        → status_code: 200   ✅
10:12:31  高德 vmap / rtt     → status_code: 200   ✅
10:12:36  [FLAGS] fetch failed → Timeout 5s        ❌
10:12:56  Load trips / Load profile / POI → Timeout 25s  ❌
10:13:04  同上                                      ❌
10:14:04~09  Quota check ×4  → Timeout 5s          ❌

同期 analytics: tab_changed → {"user_id": "<null>"}  ×4
前一日(09-13)同一用户: profile 数据完整,user_id 正常
```

### 1.2 根因排查结论

| 检查项 | 结果 | 排除的假设 |
|---|---|---|
| SCF 并发受限次数 | **无** | 不是并发超限 |
| SCF 错误率 | **无非 200** | 后端未出错 |
| `user_auth` 日志中的 `verify` 调用 | **有,Duration 正常** | 请求到达且处理完成 |
| `check_user_quota` | 冷启动 227ms + Duration 545ms ≈ 0.8s | 远低于 5s 超时阈值 |
| `generate_itinerary_stream` | 冷启动 1826ms + Duration 7332ms ≈ 9.2s | 远低于 25s 超时阈值 |
| 高德请求 | 全部 200 | 客户端网络本身可用 |
| 用户归属 | **国内测试账号(同学)** | ⚠️ 非"境外用户跨境访问广州 SCF"的结构性问题 |

> ### 🔴 结论
> **后端正常返回,响应未回到客户端 —— 网络回程丢包。**
> 这类抖动**不可消除**,是环境常态。
> **真正的缺陷在客户端:把"无法验证"当成了"已失效"。**

---

## 二、四项改动

### 🔴 改动 1:超时不得清空本地凭据(核心)

**位置:** `lib/services/backend/auth_service.dart:212-229`

**现状:**
```dart
static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentToken  = prefs.getString('auth_token');
    _currentUserId = prefs.getString('user_id');
    _loginType     = prefs.getString('login_type');
    if (_currentToken == null) return false;

    try {
        final result = await ApiClient.post(ApiClient.authUrl,
            {'action': 'verify', ...});
        return result['valid'] == true;
    } catch (e) {
        _currentToken  = null;   // ← 网络超时也走到这里
        _currentUserId = null;
        return false;
        // ← _loginType 未清空(见改动 4)
    }
}
```

**要求:必须区分两类失败**

| 情况 | 处理 |
|---|---|
| 后端明确返回 token 无效(`valid: false` / 401) | 清空凭据,视为已登出 |
| 超时 / 网络异常 / 5xx | 🔴 **保留本地凭据**,以离线态继续 |

**理由:** token 存储在本地,网络不通时无法验证,但**"无法验证"不等于"已失效"**。当前实现把不确定当成否定,导致有效会话被清除。

**影响面(实测确认):**

| 用户类型 | 当前行为 |
|---|---|
| 注册用户 | 🔴 被路由至 **LoginScreen,被迫重新登录**,而 token 其实完全有效 |
| 匿名用户 | `anonymousAuth` 重试 2 次后,**无论成败都进 MainScreen**,userId 可能为 null |

⚠️ **返回值需让调用方能区分这两种情况**(bool 不够用)。

---

### 🔴 改动 2:合并重复调用,消除竞争条件

**三个调用点:**

| 文件 | 行 | 状态 |
|---|---|---|
| `lib/main.dart` | 111 | 启动时调用 |
| `lib/screens/onboarding/splash_screen.dart` | 37 | 与 2 秒延迟 `Future.wait` 并行 |
| `lib/core/services/backend_manager.dart` | 69 | ⚠️ **僵尸代码 —— `BackendManager.initialize()` 全项目从未被调用** |

**竞争条件:**
```
main.dart      restoreSession() → 成功,设置静态字段
splash_screen  restoreSession() → 超时 → catch 清空刚设好的字段
```

⚠️ **不需要后端完全不通也会触发** —— 只要两次请求中有一次慢即可。

**要求:保留一处,另一处复用结果。** 请判断哪处更合适(考虑时序与 UI 依赖)并说明理由。

⚠️ 改动 3 会让该请求变重(查 Redis / 回落 DB),重复调用的代价随之上升。

---

### 改动 3:`verify` → `restore_session`

**位置:** `auth_service.dart:221`

```dart
- 'action': 'verify',
+ 'action': 'restore_session',
```

**两个 action 的差异(后端 `user_auth/index.py` 实测):**

| | `verify`(现状) | `restore_session`(应改为) |
|---|---|---|
| 返回 | `{valid, user_id}` | 完整用户数据,含全部订阅字段 |
| 后端实现 | 仅校验 JWT | 查 Redis 缓存 → 未命中回落 DB |
| 刷新订阅状态 | ✗ | ✅ |

**改后需补:**
```dart
SubscriptionService.instance.updateFromServer(result);
```

**理由(缺陷描述):**
```
用户订阅在离线期间到期
  → 重启 app → verify 返回 valid
  → SubscriptionService 仍持有旧缓存
  → 🔴 过期用户继续享有 premium 权限
```
直到下次完整 `login` 或手动 `updateFromServer` 才会纠正。

> 📌 后端 `restore_session` 早已实现完整逻辑,**app 侧从未调用过**。
> 这与忘记密码链路、深链缺失属同一类:**能力已具备但未接通,且无任何信号**。

⚠️ `restoreSession()` 返回类型可能需从 `Future<bool>` 调整,调用点相应适配。

---

### 改动 4:`_loginType` 清空不一致

catch 块清空 `_currentToken` / `_currentUserId` 时**未清 `_loginType`**,导致 `isAnonymous` / `isRegistered` 可能仍返回 true,与已清空的凭据状态矛盾。

**要求:** 凡清空凭据处,`_loginType` 一并清理。

---

## 三、约束

- ⛔ **不改 analytics** —— `AnalyticsService.setUser()` 全项目从未被调用,导致所有事件 `user_id` 恒为 null。**这是独立问题**,单独处理(见第六节)
- ⛔ **不做任何 Riverpod 改动** —— 本轮是行为修正,迁移是后续独立工作
- ⛔ **不删 `BackendManager`** —— 僵尸代码单独处理,但改动 2 时需知其存在,勿被该调用点误导
- ⛔ **不顺手重构** —— 发现的其他问题记入待办,不当场改
- ⛔ **禁改项照旧** —— IAP product ID / 包名 / Bundle ID / SharedPreferences key 名
- ✅ `flutter analyze` 须 0 error

---

## 四、回归清单

> ⚠️ **项目零测试覆盖**(仅 `test/widget_test.dart` 一个 `expect(true, isTrue)` 占位)。
> `flutter analyze` 0 error **不验证行为**,以下手工回归是唯一验收手段。

### 核心验证(本次修复的存在理由,不可省)

```
[ ] 🔴 已登录 + 断网 → 冷启动 → 【保持登录态】,不被踢回 LoginScreen
[ ] 🔴 已登录 + 断网 → 冷启动 → currentUserId 非 null
[ ] 🔴 模拟订阅过期 → 重启 app → Profile 显示 Free(验证改动 3)
[ ] 🔴 启动时只发一次认证请求(抓包或看 SCF 日志确认,验证改动 2)
```

### 常规回归

```
[ ] 冷启动 → 已登录用户自动恢复会话,订阅状态与服务端一致
[ ] token 真正失效(后端返回 valid:false)→ 正确降级为未登录态
[ ] 匿名用户冷启动 → 正常进入 MainScreen
[ ] 邮箱登录 / 注册 → 正常
[ ] Apple Sign-In(iOS)→ 正常
[ ] Google Sign-In(Android)→ 正常
[ ] 忘记密码全流程 → 收码 → 输码 → 改密 → 用新密码登录
[ ] Delete Account → 状态清除
[ ] Sandbox 购买(iOS)→ 全链路正常
[ ] 断网状态下各功能不崩溃、有合理提示
[ ] flutter analyze 0 error
```

⚠️ **双端登录方式不同:iOS 走 Apple Sign-In,Android 走 Google Sign-In。两端都要测。**

---

## 五、要求报告的内容

1. 每项改动的**文件与行号**
2. **改动 2 选择保留哪个调用点,及理由**
3. `restoreSession()` 的**最终签名**与返回值语义
4. 改动 1 中,如何在代码层面区分"token 无效"与"网络故障"
5. `flutter analyze` 结果

---

## 六、本轮**不做**但已登记的待办

| 项 | 性质 | 触发时机 |
|---|---|---|
| `AnalyticsService.setUser()` 从未被调用 | 🔴 **所有事件 user_id 恒为 null** | **增长铺开前必须做** —— 否则无任何用户维度数据,漏斗与留存无法计算 |
| 删除 `BackendManager` 僵尸代码 | 死代码 | 随时 |
| 防枚举补完(三层) | 安全 | 与地图英文化同版 |
| 开墙清单 B1(删除行程重置额度) | 逻辑漏洞 | 开墙前;schema 部分可提前 |
| `except` 只 `print` 处补 Sentry 上报 | 🔴 安全网 | **建议排在 Riverpod 迁移之前** |
| `src/` / `tencentcloud/` / 根 `assets/` 疑似废弃目录 | 整理 | 从容时 |
| 六个历史分支清理 | 整理 | 从容时(`v0.2_subscription_system` 已确认无独有 commit) |

---

## 七、执行纪律

1. 🔴 **一次只改一类东西** —— 本轮四项同属会话恢复链路,是一类
2. 🔴 **回归清单逐条跑完再合并** —— 零测试覆盖,手工验证是唯一防线
3. ⚠️ **多行 commit 消息用 `git commit -F 文件`**,不要粘贴 heredoc 进终端(已连续损坏两次 commit 消息)
4. ⚠️ **git 操作统一在仓库根执行** `/Users/calvinxia/Projects/WanderChina`

---

*本文件为执行指令与溯源记录。完成后勾选回归清单,归档至 `docs/decisions/`。*

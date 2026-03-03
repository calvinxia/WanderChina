# WanderChina Supabase 快速入门

**5分钟快速上手指南** 🚀

---

## 📦 已包含内容

✅ **37张数据表** - 完整的数据库架构
✅ **Row Level Security** - 所有表的安全策略
✅ **Storage 桶配置** - 6个文件存储桶
✅ **PostGIS 地理位置查询** - 支持位置搜索
✅ **种子数据** - 15个成就、6个挑战、10个地点
✅ **自动触发器** - 计数器、时间戳自动更新
✅ **分区表** - Analytics 按月分区

---

## 🚀 三步部署

### 1️⃣ 创建 Supabase 项目

```bash
1. 访问 https://app.supabase.com
2. 点击 "New Project"
3. 填写项目名称: WanderChina
4. 选择区域: Singapore / Tokyo (离中国近)
5. 设置数据库密码并保存
6. 等待 2-3 分钟初始化完成
```

### 2️⃣ 执行数据库迁移

**方法 A - 使用 Supabase CLI** (推荐)
```bash
# 安装 CLI
brew install supabase/tap/supabase

# 登录
supabase login

# 链接项目
supabase link --project-ref your-project-ref

# 推送迁移
supabase db push
```

**方法 B - 使用 SQL Editor** (手动)
```bash
1. 在 Dashboard 进入 SQL Editor
2. 依次复制粘贴并执行:
   - supabase/migrations/001_initial_schema.sql
   - supabase/migrations/002_row_level_security.sql
   - supabase/migrations/003_storage_setup.sql
   - supabase/seed.sql (可选)
```

### 3️⃣ 启用 PostGIS 扩展

```bash
1. Dashboard → Database → Extensions
2. 搜索并启用:
   ✅ postgis
   ✅ pg_trgm
   ✅ uuid-ossp (通常已启用)
```

---

## 🔑 获取 API 密钥

```bash
Dashboard → Settings → API

复制以下信息:
- Project URL: https://xxxxx.supabase.co
- anon public: eyJhbGc... (客户端使用)
- service_role: eyJhbGc... (服务端使用,保密!)
```

创建 `.env.local`:
```bash
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
```

---

## ⚙️ 必需配置

### 创建用户自动触发器 (重要!)

在 SQL Editor 执行:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, username)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    LOWER(SPLIT_PART(NEW.email, '@', 1))
  );

  INSERT INTO public.user_settings (user_id) VALUES (NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## ✅ 验证部署

在 SQL Editor 执行:

```sql
-- 1. 检查表数量 (应该是 37)
SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';

-- 2. 检查 PostGIS (应该返回版本号)
SELECT postgis_version();

-- 3. 检查种子数据
SELECT count(*) FROM public.achievements; -- 应该是 15
SELECT count(*) FROM public.challenges;   -- 应该是 6
SELECT count(*) FROM public.places;       -- 应该是 10

-- 4. 测试地理位置查询 (故宫附近5km)
SELECT name, city FROM public.get_nearby_places(39.9163, 116.3972, 5000, 5);
```

---

## 📱 客户端集成

### Flutter

```dart
// pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0

// main.dart
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'https://xxxxx.supabase.co',
  anonKey: 'your-anon-key',
);

final supabase = Supabase.instance.client;

// 使用示例
// 获取附近地点
final response = await supabase.rpc('get_nearby_places', params: {
  'user_lat': 39.9163,
  'user_lng': 116.3972,
  'radius_meters': 5000,
  'limit_count': 20,
});
```

### JavaScript/TypeScript

```bash
npm install @supabase/supabase-js
```

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://xxxxx.supabase.co',
  'your-anon-key'
)

// 获取热门地点
const { data: places } = await supabase
  .from('popular_places')
  .select('*')
  .order('saves_count', { ascending: false })
  .limit(10)

// 创建帖子
const { data: post } = await supabase
  .from('posts')
  .insert({
    content: 'Amazing view at the Great Wall!',
    images: ['/path/to/image.jpg'],
    post_type: 'photo'
  })
  .select()
  .single()
```

---

## 🔒 安全配置

### 配置 CORS (允许的域名)

```bash
Dashboard → Settings → API → CORS

添加:
- http://localhost:3000
- https://yourapp.com
```

### 配置 OAuth 登录 (可选)

```bash
Dashboard → Authentication → Providers

启用:
✅ Email (已启用)
✅ Google (需要 Client ID + Secret)
✅ Facebook (需要 App ID + Secret)
```

---

## 📚 数据库结构速览

```
用户管理 (3表)
├── users              # 用户资料
├── user_settings      # 用户设置
└── refresh_tokens     # JWT令牌

旅行规划 (2表)
├── trips              # 行程
└── itineraries        # 行程明细

地点发现 (3表)
├── places             # 景点/餐厅
├── place_reviews      # 地点评论
└── saved_places       # 收藏地点

预算管理 (1表)
└── expenses           # 支出记录

游戏化 (5表)
├── challenges         # 挑战任务
├── user_challenges    # 用户挑战进度
├── achievements       # 成就定义
├── user_achievements  # 已解锁成就
└── points_history     # 积分历史

社区社交 (6表)
├── posts              # 帖子
├── comments           # 评论
├── post_likes         # 点赞
├── comment_likes      # 评论点赞
├── saved_posts        # 收藏帖子
└── follows            # 关注关系

社交匹配 (4表)
├── companion_profiles # 旅伴资料
├── companion_matches  # 匹配结果
├── local_guides       # 本地导游
└── guide_bookings     # 导游预订

安全应急 (5表)
├── emergency_contacts # 紧急联系人
├── emergency_alerts   # SOS警报
├── location_shares    # 位置分享
├── location_updates   # GPS轨迹
└── safety_reports     # 安全报告

系统工具 (4表)
├── notifications      # 通知
├── translations_cache # 翻译缓存
├── offline_maps       # 离线地图
└── user_downloaded_maps # 用户下载的地图

预订支付 (4表)
├── bookings           # 预订记录
├── subscriptions      # 订阅
├── payments           # 支付记录
└── analytics_events   # 分析事件
```

---

## 🎯 常用查询示例

### 获取用户资料摘要
```sql
SELECT * FROM public.user_profile_summary WHERE id = 'user-uuid';
```

### 获取附近景点
```sql
SELECT * FROM public.get_nearby_places(39.9163, 116.3972, 5000, 20);
```

### 获取热门地点
```sql
SELECT * FROM public.popular_places ORDER BY saves_count DESC LIMIT 10;
```

### 获取活跃挑战
```sql
SELECT * FROM public.challenges WHERE city = 'Beijing' AND is_active = true;
```

### 上传文件 (头像)
```typescript
const file = event.target.files[0]
const { data, error } = await supabase.storage
  .from('avatars')
  .upload(`${userId}/avatar.jpg`, file, {
    cacheControl: '3600',
    upsert: true
  })
```

---

## 🚨 常见问题

**Q: 用户注册后找不到记录?**
A: 确保已创建 `handle_new_user()` 触发器

**Q: PostGIS 函数报错?**
A: Dashboard → Database → Extensions → 启用 `postgis`

**Q: 无权限访问数据?**
A: 检查 RLS 策略,确保用户已登录且 `auth.uid()` 正确

**Q: 文件上传失败?**
A: 检查文件大小限制和 Storage policies

---

## 📞 获取帮助

- 📖 完整文档: `/supabase/README.md`
- 🚀 部署指南: `/supabase/DEPLOYMENT_GUIDE.md`
- 💬 Supabase Discord: https://discord.supabase.com
- 📚 官方文档: https://supabase.com/docs

---

## ✅ 快速检查清单

- [ ] Supabase 项目已创建
- [ ] PostGIS 扩展已启用
- [ ] 3个迁移文件已执行
- [ ] 种子数据已加载 (可选)
- [ ] Auth 触发器已创建
- [ ] API 密钥已获取
- [ ] 环境变量已配置
- [ ] 数据库验证查询通过

---

**🎉 完成! 现在可以开始开发你的应用了!**

下一步:
1. 集成客户端 SDK (Flutter/React)
2. 实现用户注册登录
3. 开发核心功能

---

**更新时间:** 2025-10-23
**状态:** 🟢 可用

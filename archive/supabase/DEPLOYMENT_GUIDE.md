# WanderChina Supabase 部署指南

**版本:** 1.0.0
**更新时间:** 2025-10-23

---

## 📋 部署清单

### 前置要求

- ✅ Supabase账号 (https://supabase.com)
- ✅ Supabase CLI 已安装
- ✅ PostgreSQL 客户端工具 (psql)
- ✅ Git 仓库配置完成

---

## 🚀 快速部署 (15分钟)

### 步骤 1: 创建 Supabase 项目

1. 登录 Supabase Dashboard: https://app.supabase.com
2. 点击 **"New Project"**
3. 填写项目信息:
   - **Name**: WanderChina
   - **Database Password**: `设置强密码并保存`
   - **Region**: `选择离中国最近的区域 (Singapore 或 Tokyo)`
   - **Pricing Plan**: `Free tier 开始,后续可升级`
4. 点击 **"Create new project"**
5. 等待 2-3 分钟项目初始化完成

---

### 步骤 2: 获取项目凭证

在 Supabase Dashboard 中:

1. 进入 **Settings** → **API**
2. 复制以下信息:
   ```
   Project URL: https://xxxxx.supabase.co
   anon public key: eyJhbGc...
   service_role key: eyJhbGc... (保密!)
   ```
3. 保存到本地 `.env` 文件

---

### 步骤 3: 启用 PostGIS 扩展

1. 在 Dashboard 中进入 **Database** → **Extensions**
2. 搜索并启用以下扩展:
   - ✅ `postgis` (地理位置查询)
   - ✅ `pg_trgm` (模糊搜索)
   - ✅ `uuid-ossp` (UUID生成,通常已启用)

---

### 步骤 4: 运行数据库迁移

#### 方法 A: 使用 Supabase CLI (推荐)

```bash
# 1. 登录 Supabase
supabase login

# 2. 链接到你的项目
supabase link --project-ref your-project-ref

# 3. 推送所有迁移
supabase db push

# 4. (可选) 加载种子数据
supabase db seed
```

#### 方法 B: 使用 SQL Editor (手动)

1. 在 Dashboard 进入 **SQL Editor**
2. 按顺序执行以下文件:
   - `001_initial_schema.sql` (完整复制粘贴执行)
   - `002_row_level_security.sql`
   - `003_storage_setup.sql`
   - `seed.sql` (可选,测试数据)

---

### 步骤 5: 配置 Storage Buckets

执行 `003_storage_setup.sql` 会自动创建以下存储桶:

- `avatars` - 用户头像
- `post-images` - 帖子图片
- `place-photos` - 地点照片
- `receipts` - 收据(私密)
- `badges` - 成就徽章
- `map-tiles` - 离线地图

验证: Dashboard → **Storage** → 查看所有桶已创建

---

### 步骤 6: 配置身份验证

1. 进入 **Authentication** → **Providers**
2. 启用以下登录方式:

#### Email (已默认启用)
- ✅ Enable Email provider
- ✅ Confirm email: `可选择关闭以便测试`

#### Google OAuth
1. 创建 Google OAuth 应用: https://console.cloud.google.com
2. 获取 Client ID 和 Client Secret
3. 在 Supabase 中填入:
   - Client ID: `your-google-client-id`
   - Client Secret: `your-google-client-secret`
   - Redirect URL: `https://xxxxx.supabase.co/auth/v1/callback`

#### Facebook OAuth
1. 创建 Facebook App: https://developers.facebook.com
2. 获取 App ID 和 App Secret
3. 在 Supabase 中配置

---

### 步骤 7: 配置环境变量

创建 `.env.local` 文件:

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...your-anon-key
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...your-service-role-key

# OAuth (可选)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
FACEBOOK_CLIENT_ID=your-facebook-app-id
FACEBOOK_CLIENT_SECRET=your-facebook-app-secret

# Other APIs
BAIDU_MAPS_API_KEY=your-baidu-key
GOOGLE_TRANSLATE_API_KEY=your-google-translate-key
```

---

## 🔧 高级配置

### 自动创建 User Profile (重要!)

Supabase Auth 创建用户时,需要自动在 `public.users` 表创建记录:

```sql
-- 在 SQL Editor 执行
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

  -- 自动创建用户设置
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建触发器
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

### 设置数据库备份

1. 进入 **Database** → **Backups**
2. 配置自动备份:
   - **Daily backups**: `启用`
   - **Point-in-time recovery**: `Pro plan可用`
   - **Retention**: `7 days (Free), 30 days (Pro)`

---

### 配置数据库性能

#### 连接池设置

1. 进入 **Settings** → **Database**
2. 配置连接池:
   - **Transaction pooler**: `启用` (推荐用于 serverless)
   - **Session pooler**: `用于长连接`

#### 创建索引 (已在迁移中完成)

验证索引:
```sql
-- 查看所有索引
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

---

## 🧪 验证部署

### 1. 测试数据库连接

```sql
-- 在 SQL Editor 执行
SELECT version();
SELECT postgis_version();
```

应该返回:
- PostgreSQL 15.x
- PostGIS 3.3.x

### 2. 测试表是否创建

```sql
-- 检查表数量
SELECT count(*) FROM information_schema.tables
WHERE table_schema = 'public';
-- 应该返回 37

-- 列出所有表
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

### 3. 测试 RLS 策略

```sql
-- 查看所有 RLS 策略
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename;
```

### 4. 测试种子数据

```sql
-- 检查成就数量
SELECT count(*) FROM public.achievements;
-- 应该返回 15

-- 检查挑战数量
SELECT count(*) FROM public.challenges;
-- 应该返回 6

-- 检查地点数量
SELECT count(*) FROM public.places;
-- 应该返回 10
```

### 5. 测试 Storage

1. Dashboard → **Storage**
2. 进入 `avatars` 桶
3. 尝试手动上传一张图片
4. 验证图片可访问

### 6. 测试地理位置查询

```sql
-- 查找故宫附近的地点 (5km范围)
SELECT * FROM public.get_nearby_places(39.9163, 116.3972, 5000, 10);
```

---

## 🔒 安全配置

### 1. RLS 验证

确保所有表都启用 RLS:

```sql
-- 检查 RLS 状态
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
-- rowsecurity 应该都是 't' (true)
```

### 2. API 密钥管理

- ✅ `anon key`: 可以用于客户端
- ❌ `service_role key`: **绝对不要**暴露给客户端
- ✅ 在后端使用 service_role key 绕过 RLS

### 3. CORS 配置

1. 进入 **Settings** → **API**
2. 配置允许的域名:
   ```
   http://localhost:3000
   https://yourapp.com
   https://www.yourapp.com
   ```

---

## 📊 监控和日志

### 1. 查看 API 使用情况

Dashboard → **Reports** → **API**

监控指标:
- Request count (请求数)
- Response time (响应时间)
- Error rate (错误率)

### 2. 数据库性能

Dashboard → **Reports** → **Database**

关注:
- Active connections (活跃连接)
- Slow queries (慢查询)
- Database size (数据库大小)

### 3. Storage 使用

Dashboard → **Reports** → **Storage**

- Total storage used
- Bandwidth used

---

## 🚨 常见问题排查

### 问题 1: 用户注册后 `public.users` 表没有记录

**解决方案**: 创建 trigger (见上文 "自动创建 User Profile")

### 问题 2: PostGIS 函数报错

**检查**:
```sql
SELECT * FROM pg_extension WHERE extname = 'postgis';
```

**修复**: Dashboard → Database → Extensions → 启用 PostGIS

### 问题 3: RLS 导致无法访问数据

**临时调试** (仅开发环境):
```sql
-- 临时禁用某表 RLS (危险!)
ALTER TABLE public.your_table DISABLE ROW LEVEL SECURITY;

-- 记得重新启用
ALTER TABLE public.your_table ENABLE ROW LEVEL SECURITY;
```

**正确方法**: 检查 RLS 策略是否正确

### 问题 4: Storage 上传失败

**检查 Policy**:
```sql
-- 查看 storage.objects 策略
SELECT * FROM pg_policies WHERE tablename = 'objects';
```

**验证文件大小**: 不超过桶限制 (avatars: 5MB, post-images: 10MB)

---

## 📈 扩展和优化

### 升级到 Pro Plan 的时机

当满足以下条件时考虑升级:
- ✅ 超过 500MB 数据库存储
- ✅ 超过 1GB 文件存储
- ✅ 需要每日自动备份
- ✅ 需要更多并发连接 (>60)
- ✅ 需要自定义域名

### 性能优化建议

1. **启用 Connection Pooler** (Transaction mode)
2. **定期 VACUUM**:
   ```sql
   VACUUM ANALYZE;
   ```
3. **监控慢查询**:
   ```sql
   SELECT * FROM pg_stat_statements
   ORDER BY total_time DESC
   LIMIT 10;
   ```
4. **添加缺失的索引** (根据实际查询分析)

---

## 🔄 数据迁移 (从其他数据库)

如果你需要从其他数据库迁移:

### 从 PostgreSQL

```bash
# 导出数据
pg_dump -U username -d old_database > backup.sql

# 导入到 Supabase
psql -h db.xxxxx.supabase.co -U postgres -d postgres < backup.sql
```

### 从 MySQL

使用工具: https://github.com/philipsoutham/py-mysql2pgsql

---

## 📞 获取帮助

- **Supabase Discord**: https://discord.supabase.com
- **Supabase Docs**: https://supabase.com/docs
- **Stack Overflow**: Tag `supabase`
- **GitHub Issues**: https://github.com/supabase/supabase/issues

---

## ✅ 部署完成检查清单

- [ ] Supabase 项目已创建
- [ ] PostGIS 扩展已启用
- [ ] 所有迁移文件已执行
- [ ] 37个表已创建
- [ ] RLS 策略已应用 (所有表)
- [ ] Storage 桶已创建 (6个)
- [ ] Auth 触发器已创建
- [ ] 种子数据已加载 (可选)
- [ ] 环境变量已配置
- [ ] Google/Facebook OAuth 已配置 (可选)
- [ ] 数据库连接已测试
- [ ] API 密钥已保存
- [ ] 备份策略已配置

---

**恭喜! 🎉 你的 WanderChina Supabase 数据库已成功部署!**

下一步: 开始构建你的应用程序前端和后端

---

**最后更新:** 2025-10-23
**文档版本:** 1.0
**状态:** 🟢 生产就绪

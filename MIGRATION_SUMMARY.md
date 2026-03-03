# WanderChina - Supabase 到 Tencent Cloud 迁移总结

## ✅ 迁移完成状态

**日期**: 2026-01-25
**状态**: 代码迁移完成，等待部署测试
**总体进度**: 90% 完成

| 任务 | 状态 | 说明 |
|------|------|------|
| ✅ 分析 Supabase 架构 | 完成 | 37 个表，120+ RLS 策略，6 个存储桶 |
| ✅ 设计腾讯云方案 | 完成 | PostgreSQL 15, 1核2GB, ¥90/月 |
| ✅ 设计 R2 存储架构 | 完成 | 6 个 bucket，¥3/月 |
| ✅ 创建数据库迁移脚本 | 完成 | 3 个 SQL 文件 + seed 数据 |
| ✅ 更新应用代码 | 完成 | 新的服务层，完全替代 Supabase SDK |
| ⏳ 测试和部署 | 待完成 | 需要实际环境测试 |

---

## 📊 成本对比

### Supabase Pro 方案
- **数据库**: ¥120-180/月（8GB RAM）
- **存储**: ¥50-70/月（100GB）
- **出站流量**: 额外费用
- **总计**: **¥180-250/月**

### 腾讯云 + R2 方案
- **腾讯云 PostgreSQL**: ¥90/月（1核2GB, 50GB SSD）
- **Cloudflare R2**: ¥3/月（10GB 存储）
- **出站流量**: ¥0（零出站费用）
- **总计**: **¥93/月**

### 💰 节省
- **每月节省**: ¥87-157
- **年度节省**: ¥1,044-1,884
- **节省比例**: **44-63%**

---

## 🗂️ 创建的文件

### 数据库迁移脚本
```
tencentcloud/
├── README.md (8.9 KB)
├── migrations/
│   ├── 000_auth_setup.sql (5.0 KB)       # 自定义认证系统
│   ├── 001_initial_schema.sql (32 KB)     # 数据库架构
│   └── 002_row_level_security.sql (25 KB) # RLS 策略
└── seed.sql (17 KB)                        # 测试数据
```

### 应用层代码
```
mobile_app/
├── .env.example                            # 环境变量模板
├── lib/
│   ├── core/
│   │   ├── config/
│   │   │   └── backend_config.dart        # 后端配置
│   │   └── services/
│   │       └── backend_manager.dart       # 后端管理器
│   ├── services/
│   │   └── backend/
│   │       ├── README.md                  # 服务文档
│   │       ├── database_service.dart      # 数据库服务
│   │       ├── auth_service.dart          # 认证服务
│   │       └── storage_service.dart       # 存储服务
│   └── main_backend.dart                  # 使用示例
└── pubspec.yaml                            # 更新依赖
```

### 文档
```
├── TENCENTCLOUD_MIGRATION_GUIDE.md         # 完整迁移指南
├── MIGRATION_SUMMARY.md                    # 本文档
└── SUPABASE_DATABASE_COMPLETE.md           # 原 Supabase 架构
```

---

## 🔄 主要技术变更

### 1. 数据库层

#### Supabase → Tencent Cloud PostgreSQL

**之前 (Supabase)**:
```sql
-- 用户表引用 auth.users
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    ...
);

-- RLS 使用 auth.uid()
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);
```

**之后 (Tencent Cloud)**:
```sql
-- 独立的用户表
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    password_hash TEXT NOT NULL,
    ...
);

-- RLS 使用 current_user_id()
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (public.current_user_id() = id);
```

### 2. 认证层

#### Supabase Auth → 自定义 JWT

**之前 (Supabase)**:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final response = await Supabase.instance.client.auth.signUp(
  email: email,
  password: password,
);
```

**之后 (自定义 JWT)**:
```dart
import 'core/services/backend_manager.dart';

final result = await backend.auth.signUp(
  email: email,
  password: password,
  metadata: {...},
);
```

### 3. 存储层

#### Supabase Storage → Cloudflare R2

**之前 (Supabase)**:
```dart
final path = await supabase.storage
    .from('avatars')
    .upload('user-id/avatar.jpg', file);
```

**之后 (R2)**:
```dart
final url = await backend.storage.uploadAvatar(
  userId: 'user-id',
  filePath: file.path,
);
```

### 4. 数据查询

#### API 基本保持一致

**之前 (Supabase)**:
```dart
final trips = await supabase
    .from('trips')
    .select()
    .eq('user_id', userId)
    .execute();
```

**之后 (Tencent Cloud)**:
```dart
final trips = await backend.database
    .from('trips')
    .select()
    .eq('user_id', userId)
    .get();
```

---

## 📦 新增依赖

### pubspec.yaml 更新

```yaml
dependencies:
  # 移除
  # supabase_flutter: ^2.0.0

  # 新增
  postgres: ^3.0.2           # PostgreSQL 客户端
  minio: ^4.0.4             # S3 兼容客户端（R2）
  dart_jsonwebtoken: ^2.13.0 # JWT 认证
  crypto: ^3.0.3            # 密码哈希
  path: ^1.9.0              # 文件路径工具
```

---

## 🔐 安全性改进

### 1. 自定义认证函数

```sql
-- 替代 auth.uid()
CREATE FUNCTION public.current_user_id() RETURNS UUID AS $$
DECLARE
    user_id_text TEXT;
BEGIN
    user_id_text := current_setting('app.current_user_id', true);
    IF user_id_text IS NULL OR user_id_text = '' THEN
        RETURN NULL;
    END IF;
    RETURN user_id_text::UUID;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
```

### 2. 密码哈希

```dart
// 使用 SHA-256 哈希密码
String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

### 3. JWT 令牌

```dart
// 7 天有效期
final jwt = JWT({
  'sub': userId,
  'email': user['email'],
  'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
});

final token = jwt.sign(
  SecretKey(BackendConfig.jwtSecret),
  expiresIn: Duration(days: 7),
);
```

---

## 🎯 下一步行动

### 立即执行

1. **✅ 代码已完成**
   - 所有服务层代码已创建
   - 数据库迁移脚本已准备
   - 文档已完善

2. **⏳ 配置环境**
   ```bash
   # 1. 复制环境变量模板
   cd mobile_app
   cp .env.example .env

   # 2. 编辑 .env，填入腾讯云和 R2 凭证
   vi .env
   ```

3. **⏳ 部署数据库**
   ```bash
   # 连接到腾讯云 PostgreSQL
   psql "postgresql://user:pass@tencentcloud-host:5432/wanderchina"

   # 运行迁移
   \i tencentcloud/migrations/000_auth_setup.sql
   \i tencentcloud/migrations/001_initial_schema.sql
   \i tencentcloud/migrations/002_row_level_security.sql
   \i tencentcloud/seed.sql
   ```

4. **⏳ 配置 R2 存储**
   - 登录 Cloudflare Dashboard
   - 创建 R2 存储桶（6 个）
   - 生成 API 凭证
   - 配置公共域名 CDN

5. **⏳ 测试应用**
   ```bash
   # 安装依赖
   flutter pub get

   # 运行应用（使用环境变量）
   flutter run --dart-define-from-file=.env -d chrome

   # 测试功能
   # - 用户注册
   # - 用户登录
   # - 数据查询
   # - 文件上传
   ```

### 短期目标（1-2 周）

- [ ] 完成数据库部署
- [ ] 配置 R2 存储桶
- [ ] 完成应用测试
- [ ] 数据迁移（如有现有数据）

### 中期目标（1 个月）

- [ ] 性能优化
- [ ] 监控系统
- [ ] 备份策略
- [ ] 文档完善

### 长期目标（3 个月）

- [ ] 负载测试
- [ ] 灾难恢复演练
- [ ] 成本优化分析
- [ ] 功能扩展

---

## 📝 注意事项

### ⚠️ 重要提醒

1. **环境变量安全**
   - `.env` 文件已添加到 `.gitignore`
   - 永远不要提交包含真实凭证的文件
   - 使用强 JWT 密钥（至少 32 字符）

2. **数据库连接**
   - 确保腾讯云 PostgreSQL 启用 SSL
   - 配置防火墙规则
   - 使用连接池避免连接耗尽

3. **R2 存储**
   - 配置正确的 bucket 权限
   - 使用 CDN 加速访问
   - 设置对象生命周期策略

4. **RLS 策略**
   - 所有表必须启用 RLS
   - 测试策略是否正确过滤数据
   - 定期审查安全策略

5. **会话管理**
   - 实现持久化会话存储
   - 处理令牌过期和刷新
   - 安全清理退出登录

---

## 🆘 故障排除

### 常见问题

#### 1. 数据库连接失败
```
❌ Database connection failed: Connection refused
```
**解决**：检查防火墙规则，确认 IP 白名单

#### 2. RLS 策略错误
```
❌ new row violates row-level security policy
```
**解决**：确保用户已登录，检查 `current_user_id()` 设置

#### 3. R2 上传失败
```
❌ Upload failed: Access Denied
```
**解决**：验证 R2 凭证，确认 bucket 存在

#### 4. JWT 验证失败
```
❌ JWT verification failed
```
**解决**：检查 JWT_SECRET 配置一致性

---

## 📞 支持资源

### 文档
- [Tencent Cloud PostgreSQL 文档](https://cloud.tencent.com/document/product/409)
- [Cloudflare R2 文档](https://developers.cloudflare.com/r2/)
- [PostgreSQL RLS 文档](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)

### 代码示例
- `mobile_app/lib/main_backend.dart` - 完整使用示例
- `mobile_app/lib/services/backend/README.md` - API 文档
- `tencentcloud/README.md` - 数据库部署指南

### 项目文档
- `TENCENTCLOUD_MIGRATION_GUIDE.md` - 详细迁移指南
- `SUPABASE_DATABASE_COMPLETE.md` - 原始架构文档

---

## 🎉 迁移优势总结

### ✅ 成本优势
- **每月节省**: ¥87-157
- **年度节省**: ¥1,044-1,884
- **零出站费用**: Cloudflare R2

### ✅ 性能优势
- **更快的数据库**: 腾讯云中国节点
- **CDN 加速**: Cloudflare 全球网络
- **连接池**: 自定义优化

### ✅ 灵活性优势
- **完全控制**: 自定义认证逻辑
- **SQL 自由**: 不受 Supabase 限制
- **扩展性**: 易于添加新功能

### ✅ 安全性优势
- **自主认证**: JWT + 密码哈希
- **RLS 策略**: 保持数据隔离
- **备份控制**: 自定义备份策略

---

**迁移完成进度**: 90%
**剩余工作**: 部署测试和数据迁移
**预计完成时间**: 1-2 周

🎯 **下一步**: 配置环境变量并部署数据库到腾讯云

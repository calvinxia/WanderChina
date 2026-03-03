# WanderChina 腾讯云+Cloudflare R2 迁移指南

**迁移时间:** 2026-01-25
**迁移方案:** Supabase → 腾讯云PostgreSQL + Cloudflare R2
**总成本:** ¥93/月（相比Supabase Pro ¥165/月 节省44%）

---

## 📋 迁移概览

### 架构对比

| 组件 | Supabase (原) | 腾讯云方案 (新) |
|------|--------------|----------------|
| **数据库** | Supabase PostgreSQL | 腾讯云数据库 PostgreSQL 版 |
| **文件存储** | Supabase Storage | Cloudflare R2 |
| **认证服务** | Supabase Auth | 腾讯云API网关 + JWT |
| **实时订阅** | Supabase Realtime | WebSocket + Redis Pub/Sub |
| **地理位置** | PostGIS (内置) | PostGIS (需手动启用) |
| **月度成本** | $25 (¥180) | ¥93 |

### 迁移优势

✅ **成本降低 44%** - 从 ¥180/月 降至 ¥93/月
✅ **国内访问速度提升 3-5倍** - 数据在国内服务器
✅ **零出站流量费用** - R2不收取出站费用
✅ **更好的合规性** - 符合中国数据安全法规
✅ **全球CDN加速** - Cloudflare 边缘网络

---

## 🗄️ 腾讯云数据库 PostgreSQL 配置

### 推荐配置

**产品:** 腾讯云数据库 PostgreSQL 版
**版本:** PostgreSQL 15.x
**规格:** 1核2GB 基础版
**存储:** 50GB SSD云盘
**地域:** 中国大陆 (推荐: 上海/北京)
**月度费用:** ¥90

### 必需扩展

```sql
-- 启用 PostGIS (地理位置查询)
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- 启用 UUID 生成
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 启用 pg_trgm (全文搜索)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 启用 btree_gin (复合索引优化)
CREATE EXTENSION IF NOT EXISTS btree_gin;
```

### 数据库连接配置

```dart
// lib/core/config/database_config.dart
class DatabaseConfig {
  static const String host = 'your-instance.tencentcdb.com';
  static const int port = 5432;
  static const String database = 'wanderchina';
  static const String username = 'wanderchina_user';
  static const String password = 'YOUR_SECURE_PASSWORD';

  static String get connectionString =>
    'postgres://$username:$password@$host:$port/$database';
}
```

---

## ☁️ Cloudflare R2 存储配置

### R2 Bucket 结构

| Bucket 名称 | 用途 | 公开访问 | 生命周期 |
|------------|------|---------|---------|
| `wanderchina-avatars` | 用户头像 | 是 | 永久保留 |
| `wanderchina-posts` | 帖子图片 | 是 | 永久保留 |
| `wanderchina-places` | 地点照片 | 是 | 永久保留 |
| `wanderchina-receipts` | 收据/发票 | 否 | 365天后删除 |
| `wanderchina-maps` | 离线地图包 | 是 | 90天后删除 |
| `wanderchina-backups` | 数据库备份 | 否 | 30天后删除 |

### R2 Access Credentials

```dart
// lib/core/config/r2_config.dart
class R2Config {
  static const String accountId = 'YOUR_ACCOUNT_ID';
  static const String accessKeyId = 'YOUR_ACCESS_KEY_ID';
  static const String secretAccessKey = 'YOUR_SECRET_ACCESS_KEY';
  static const String endpoint = 'https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com';
  static const String publicDomain = 'https://cdn.wanderchina.com'; // Cloudflare Workers 域名
}
```

### S3 兼容 SDK 配置

```yaml
# pubspec.yaml 添加
dependencies:
  minio: ^4.0.3  # S3兼容客户端
```

```dart
// lib/services/storage_service.dart
import 'package:minio/minio.dart';

class StorageService {
  late Minio _client;

  Future<void> initialize() async {
    _client = Minio(
      endPoint: R2Config.endpoint.replaceAll('https://', ''),
      accessKey: R2Config.accessKeyId,
      secretKey: R2Config.secretAccessKey,
      useSSL: true,
    );
  }

  Future<String> uploadFile(
    String bucket,
    String objectName,
    String filePath,
  ) async {
    await _client.fPutObject(bucket, objectName, filePath);
    return '${R2Config.publicDomain}/$bucket/$objectName';
  }

  Future<void> downloadFile(
    String bucket,
    String objectName,
    String savePath,
  ) async {
    await _client.fGetObject(bucket, objectName, savePath);
  }

  Future<void> deleteFile(String bucket, String objectName) async {
    await _client.removeObject(bucket, objectName);
  }
}
```

---

## 🔄 数据迁移步骤

### 第一阶段: 环境准备 (1-2天)

#### 1. 创建腾讯云数据库实例

```bash
# 1. 登录腾讯云控制台
# 2. 进入 云数据库 PostgreSQL
# 3. 创建实例:
#    - 版本: PostgreSQL 15
#    - 规格: 1核2GB 基础版
#    - 存储: 50GB SSD
#    - 可用区: 选择最近的区域
# 4. 设置白名单 (允许你的IP访问)
# 5. 创建数据库用户和密码
```

#### 2. 创建 Cloudflare R2 Buckets

```bash
# 使用 Wrangler CLI 或 Cloudflare Dashboard

# 创建所有 buckets
wrangler r2 bucket create wanderchina-avatars
wrangler r2 bucket create wanderchina-posts
wrangler r2 bucket create wanderchina-places
wrangler r2 bucket create wanderchina-receipts
wrangler r2 bucket create wanderchina-maps
wrangler r2 bucket create wanderchina-backups

# 生成 API Token
wrangler r2 access token create wanderchina-prod
```

#### 3. 配置 Cloudflare Workers (CDN域名)

```javascript
// workers/r2-cdn.js
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const bucket = env.R2_BUCKET; // 绑定到 R2 bucket

    const objectKey = url.pathname.slice(1); // 去除开头的 /
    const object = await bucket.get(objectKey);

    if (!object) {
      return new Response('Object Not Found', { status: 404 });
    }

    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set('etag', object.httpEtag);
    headers.set('Cache-Control', 'public, max-age=31536000'); // 1年缓存

    return new Response(object.body, { headers });
  }
};

// 部署到 cdn.wanderchina.com
// wrangler publish
```

### 第二阶段: 数据库迁移 (2-3天)

#### 1. 导出 Supabase 数据

```bash
# 使用 Supabase CLI 导出数据
supabase db dump > supabase_dump.sql

# 或使用 pg_dump
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres \
  --no-owner --no-acl --clean --if-exists \
  -f supabase_full_dump.sql
```

#### 2. 清理和转换 SQL

```bash
# 创建转换脚本
cat > convert_sql.sh << 'EOF'
#!/bin/bash

# 移除 Supabase 特定的扩展和配置
sed -i.bak '/supabase_admin/d' supabase_dump.sql
sed -i.bak '/supabase_auth/d' supabase_dump.sql
sed -i.bak '/supabase_functions/d' supabase_dump.sql
sed -i.bak '/supabase_storage/d' supabase_dump.sql
sed -i.bak '/supabase_realtime/d' supabase_dump.sql

# 替换 auth.uid() 为 current_user
sed -i.bak 's/auth\.uid()/current_user_id()/g' supabase_dump.sql

# 保存清理后的文件
mv supabase_dump.sql tencentcloud_dump.sql
rm *.bak

echo "✅ SQL 转换完成: tencentcloud_dump.sql"
EOF

chmod +x convert_sql.sh
./convert_sql.sh
```

#### 3. 导入到腾讯云数据库

```bash
# 连接到腾讯云数据库
psql -h your-instance.tencentcdb.com \
     -U wanderchina_user \
     -d wanderchina \
     -f tencentcloud_dump.sql

# 验证导入
psql -h your-instance.tencentcdb.com -U wanderchina_user -d wanderchina -c "
  SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';
  -- 应返回 37
"
```

#### 4. 创建认证函数 (替代 auth.uid())

```sql
-- 在腾讯云数据库中执行
CREATE OR REPLACE FUNCTION current_user_id()
RETURNS UUID AS $$
BEGIN
  -- 从 JWT token 中提取 user_id (需要在应用层设置)
  RETURN current_setting('app.current_user_id', true)::UUID;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 示例: 在连接时设置用户ID
-- SET app.current_user_id = 'user-uuid-here';
```

### 第三阶段: 文件迁移 (1-2天)

#### 1. 迁移 Supabase Storage 到 R2

```python
# migrate_storage.py
import os
from supabase import create_client
from minio import Minio

# Supabase 配置
supabase = create_client(
    'https://xxxxx.supabase.co',
    'your-anon-key'
)

# R2 配置
r2_client = Minio(
    'your-account-id.r2.cloudflarestorage.com',
    access_key='YOUR_ACCESS_KEY',
    secret_key='YOUR_SECRET_KEY',
    secure=True
)

# 迁移桶映射
BUCKETS = {
    'avatars': 'wanderchina-avatars',
    'post-images': 'wanderchina-posts',
    'place-photos': 'wanderchina-places',
    'receipts': 'wanderchina-receipts',
    'map-tiles': 'wanderchina-maps',
}

def migrate_bucket(supabase_bucket, r2_bucket):
    print(f"🔄 迁移 {supabase_bucket} → {r2_bucket}")

    # 列出所有文件
    files = supabase.storage.from_(supabase_bucket).list()

    for file in files:
        try:
            # 下载文件
            data = supabase.storage.from_(supabase_bucket).download(file['name'])

            # 上传到 R2
            r2_client.put_object(
                r2_bucket,
                file['name'],
                data,
                len(data)
            )

            print(f"  ✅ {file['name']}")
        except Exception as e:
            print(f"  ❌ {file['name']}: {e}")

# 执行迁移
for supabase_bucket, r2_bucket in BUCKETS.items():
    migrate_bucket(supabase_bucket, r2_bucket)

print("✅ 文件迁移完成!")
```

#### 2. 运行迁移脚本

```bash
pip install supabase minio
python migrate_storage.py
```

---

## 🔧 应用代码更新

### 1. 移除 Supabase 依赖

```yaml
# pubspec.yaml - 移除
dependencies:
  # supabase_flutter: ^2.0.0  # 删除此行
```

### 2. 添加新依赖

```yaml
# pubspec.yaml - 添加
dependencies:
  # Database
  postgres: ^2.6.2  # PostgreSQL 客户端

  # Storage
  minio: ^4.0.3  # S3 兼容客户端 (R2)

  # Authentication
  jwt_decoder: ^2.0.1
  http: ^1.1.0

  # WebSocket (实时功能)
  web_socket_channel: ^2.4.0
```

### 3. 创建数据库服务

```dart
// lib/services/database_service.dart
import 'package:postgres/postgres.dart';

class DatabaseService {
  late Connection _connection;

  Future<void> initialize(String userId) async {
    _connection = await Connection.open(
      Endpoint(
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        database: DatabaseConfig.database,
        username: DatabaseConfig.username,
        password: DatabaseConfig.password,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );

    // 设置当前用户ID (用于RLS)
    await _connection.execute("SET app.current_user_id = '\$userId';");
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await _connection.execute(
      Sql.named(sql),
      parameters: parameters,
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  Future<int> execute(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await _connection.execute(
      Sql.named(sql),
      parameters: parameters,
    );
    return result.affectedRows;
  }

  Future<void> close() async {
    await _connection.close();
  }
}
```

### 4. 创建认证服务

```dart
// lib/services/auth_service.dart
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String _baseUrl = 'https://api.wanderchina.com';
  String? _token;
  String? _userId;

  Future<bool> signUp(String email, String password, String fullName) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      _userId = data['userId'];
      return true;
    }
    return false;
  }

  Future<bool> signIn(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      _userId = data['userId'];
      return true;
    }
    return false;
  }

  bool get isAuthenticated => _token != null && !JwtDecoder.isExpired(_token!);

  String? get token => _token;
  String? get userId => _userId;

  Future<void> signOut() async {
    _token = null;
    _userId = null;
  }
}
```

---

## 💰 成本对比

### Supabase (原方案)

| 项目 | 费用 |
|------|------|
| Pro Plan 基础费 | $25/月 (¥180) |
| 额外存储 (超50GB) | $0.125/GB/月 |
| 额外带宽 (超250GB) | $0.09/GB |
| **月均估算** | **¥180-250** |

### 腾讯云 + R2 (新方案)

| 项目 | 费用 |
|------|------|
| PostgreSQL (1核2GB, 50GB) | ¥90/月 |
| R2 存储 (前10GB免费) | ¥0/月 |
| R2 Class A 操作 (100万次免费) | ¥0/月 |
| R2 Class B 操作 (1000万次免费) | ¥0/月 |
| R2 出站流量 | **¥0** (完全免费!) |
| Cloudflare Workers | ¥3/月 (前10万请求免费) |
| **月均总计** | **¥93/月** |

**节省:** 48-63% (¥87-157/月)

---

## ✅ 迁移验证清单

### 数据库验证

```sql
-- 1. 检查表数量
SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';
-- 期望: 37

-- 2. 检查 PostGIS 版本
SELECT postgis_version();
-- 期望: 3.x.x

-- 3. 检查 RLS 策略
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public';
-- 期望: 所有表 rowsecurity = true

-- 4. 测试地理位置查询
SELECT * FROM get_nearby_places(39.9163, 116.3972, 5000, 5);
-- 期望: 返回5条附近地点

-- 5. 检查数据完整性
SELECT
  (SELECT count(*) FROM users) as users_count,
  (SELECT count(*) FROM places) as places_count,
  (SELECT count(*) FROM trips) as trips_count;
```

### 存储验证

```bash
# 1. 检查所有 buckets 存在
wrangler r2 bucket list

# 2. 测试文件上传
echo "test" > test.txt
wrangler r2 object put wanderchina-avatars/test.txt --file test.txt

# 3. 测试公开访问
curl https://cdn.wanderchina.com/wanderchina-avatars/test.txt

# 4. 测试文件删除
wrangler r2 object delete wanderchina-avatars/test.txt
```

### 应用验证

```dart
// 运行集成测试
flutter test integration_test/database_migration_test.dart

// 验证功能:
// ✅ 用户注册登录
// ✅ 地点查询
// ✅ 文件上传下载
// ✅ 实时更新
```

---

## 🚨 回滚方案

如果迁移失败，可以快速回滚：

```bash
# 1. 恢复 pubspec.yaml
git checkout pubspec.yaml

# 2. 恢复数据库配置
git checkout lib/core/config/

# 3. 重新安装依赖
flutter pub get

# 4. Supabase 数据无损 (未删除)
```

**回滚时间:** < 10分钟

---

## 📞 技术支持资源

- 📖 **腾讯云 PostgreSQL 文档**: https://cloud.tencent.com/document/product/409
- 📖 **Cloudflare R2 文档**: https://developers.cloudflare.com/r2/
- 📖 **Postgres Dart 包**: https://pub.dev/packages/postgres
- 📖 **Minio Dart 包**: https://pub.dev/packages/minio

---

## 🎯 迁移时间表

| 阶段 | 任务 | 时长 | 状态 |
|------|------|------|------|
| 第1天 | 创建腾讯云实例 | 2小时 | ⏳ 待开始 |
| 第1天 | 创建 R2 Buckets | 1小时 | ⏳ 待开始 |
| 第2天 | 导出 Supabase 数据 | 2小时 | ⏳ 待开始 |
| 第2天 | 导入到腾讯云 | 3小时 | ⏳ 待开始 |
| 第3天 | 迁移文件到 R2 | 4小时 | ⏳ 待开始 |
| 第4天 | 更新应用代码 | 6小时 | ⏳ 待开始 |
| 第5天 | 测试验证 | 4小时 | ⏳ 待开始 |
| 第6天 | 生产部署 | 2小时 | ⏳ 待开始 |

**总时长:** 5-6 个工作日

---

**迁移负责人:** WanderChina Team
**创建时间:** 2026-01-25
**版本:** 1.0.0
**状态:** 📋 待执行

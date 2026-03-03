# Backend Services

完整的后端服务层，用于替代 Supabase SDK，支持 Tencent Cloud PostgreSQL 和 Cloudflare R2。

## 📁 文件结构

```
lib/
├── core/
│   ├── config/
│   │   └── backend_config.dart          # 后端配置
│   └── services/
│       └── backend_manager.dart         # 后端管理器（单一初始化入口）
│
└── services/
    └── backend/
        ├── database_service.dart        # 数据库服务（PostgreSQL）
        ├── auth_service.dart            # 认证服务（JWT）
        └── storage_service.dart         # 存储服务（R2）
```

## 🚀 快速开始

### 1. 配置环境变量

```bash
# 复制示例文件
cp .env.example .env

# 编辑 .env 文件，填入你的凭证
vi .env
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 初始化后端

```dart
import 'core/services/backend_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化后端
  await backend.initialize();

  runApp(MyApp());
}
```

### 4. 使用服务

```dart
// 用户注册
final result = await backend.auth.signUp(
  email: 'user@example.com',
  password: 'secure-password',
  metadata: {
    'username': 'traveler123',
    'full_name': 'John Doe',
  },
);

// 查询数据
final trips = await backend.database
    .from('trips')
    .select()
    .eq('user_id', backend.auth.currentUserId)
    .get();

// 上传文件
final url = await backend.storage.uploadAvatar(
  userId: backend.auth.currentUserId!,
  filePath: '/path/to/avatar.jpg',
);
```

## 📚 服务详解

### DatabaseService - 数据库服务

提供类 Supabase 的数据库查询 API：

```dart
// 基础查询
final trips = await backend.database
    .from('trips')
    .select()
    .eq('status', 'planning')
    .order('created_at', ascending: false)
    .limit(10)
    .get();

// 插入
final newTrip = await backend.database.from('trips').insert({
  'user_id': backend.auth.currentUserId,
  'title': 'Beijing Adventure',
  'start_date': '2026-03-01',
  'end_date': '2026-03-07',
});

// 更新
await backend.database
    .from('trips')
    .eq('id', tripId)
    .update({'status': 'completed'});

// 删除
await backend.database
    .from('trips')
    .eq('id', tripId)
    .delete();

// 原生 SQL
final result = await backend.database.query('''
  SELECT * FROM places
  WHERE ST_DWithin(
    location,
    ST_SetSRID(ST_MakePoint(@lng, @lat), 4326)::geography,
    @radius
  )
  ORDER BY rating DESC
  LIMIT @limit
''', parameters: {
  'lat': 39.9042,
  'lng': 116.4074,
  'radius': 5000,
  'limit': 20,
});

// 事务
await backend.database.transaction((ctx) async {
  // 在事务中执行多个操作
  await ctx.execute('UPDATE accounts SET balance = balance - 100 WHERE id = @id');
  await ctx.execute('INSERT INTO transactions ...');
});
```

### AuthService - 认证服务

基于 JWT 的用户认证：

```dart
// 注册
final result = await backend.auth.signUp(
  email: 'user@example.com',
  password: 'secure-password',
  metadata: {
    'username': 'traveler123',
    'full_name': 'John Doe',
    'nationality': 'USA',
    'languages': ['en', 'zh'],
  },
);

// 登录
final session = await backend.auth.signIn(
  email: 'user@example.com',
  password: 'secure-password',
);

// 检查认证状态
if (backend.auth.isAuthenticated) {
  print('User ID: ${backend.auth.currentUserId}');
  print('Email: ${backend.auth.currentUserEmail}');
}

// 修改密码
await backend.auth.changePassword(
  currentPassword: 'old-password',
  newPassword: 'new-password',
);

// 登出
await backend.auth.signOut();
```

### StorageService - 存储服务

Cloudflare R2 对象存储（S3 兼容）：

```dart
// 上传头像
final avatarUrl = await backend.storage.uploadAvatar(
  userId: backend.auth.currentUserId!,
  filePath: '/path/to/avatar.jpg',
);

// 上传帖子图片
final imageUrl = await backend.storage.uploadPostImage(
  userId: backend.auth.currentUserId!,
  postId: 'post-uuid',
  filePath: '/path/to/photo.jpg',
);

// 上传地点照片
final placePhotoUrl = await backend.storage.uploadPlacePhoto(
  placeId: 'place-uuid',
  filePath: '/path/to/place.jpg',
);

// 上传收据（私有）
final receiptUrl = await backend.storage.uploadReceipt(
  userId: backend.auth.currentUserId!,
  expenseId: 'expense-uuid',
  filePath: '/path/to/receipt.pdf',
);

// 上传字节数据（适用于 Web）
final url = await backend.storage.uploadBytes(
  bucket: 'post-images',
  objectName: 'user/post/image.jpg',
  bytes: imageBytes,
  contentType: 'image/jpeg',
);

// 删除文件
await backend.storage.deleteFile(
  bucket: 'post-images',
  objectName: 'user/post/image.jpg',
);

// 批量删除
await backend.storage.deleteFiles(
  bucket: 'post-images',
  objectNames: ['file1.jpg', 'file2.jpg'],
);

// 列出对象
final objects = await backend.storage.listObjects(
  bucket: 'post-images',
  prefix: 'user-id/',
);
```

## 🔐 Row Level Security (RLS)

所有数据库查询自动应用 RLS 策略。用户登录后，`current_user_id()` 会自动设置：

```dart
// 登录后自动设置用户上下文
await backend.auth.signIn(email: email, password: password);

// 现在所有查询都使用 RLS 过滤
final myTrips = await backend.database.from('trips').select().get();
// 只返回当前用户的旅行，因为 RLS 策略会自动添加 WHERE user_id = current_user_id()
```

## ⚙️ 配置

### 环境变量 (.env)

```bash
# 数据库
DB_HOST=your-tencentcloud-host.com
DB_PORT=5432
DB_NAME=wanderchina
DB_USERNAME=postgres
DB_PASSWORD=your-password
DB_SSL=true

# 存储
R2_ACCOUNT_ID=your-account-id
R2_ACCESS_KEY_ID=your-access-key
R2_SECRET_ACCESS_KEY=your-secret-key
R2_PUBLIC_DOMAIN=https://cdn.wanderchina.app

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
```

### 运行应用

```bash
# 使用环境变量运行
flutter run --dart-define-from-file=.env

# 或者直接传递参数
flutter run \
  --dart-define=DB_HOST=your-host \
  --dart-define=DB_PASSWORD=your-password \
  --dart-define=R2_ACCESS_KEY_ID=your-key
```

## 📊 与 Supabase 的对比

| 功能 | Supabase | Tencent Cloud + R2 |
|------|----------|-------------------|
| **数据库** | `supabase.from('table')` | `backend.database.from('table')` |
| **认证** | `supabase.auth.signUp()` | `backend.auth.signUp()` |
| **存储** | `supabase.storage.upload()` | `backend.storage.uploadFile()` |
| **RLS** | 自动应用 | 自动应用（通过 current_user_id()） |
| **Realtime** | 内置 | 需要自定义 WebSocket |
| **成本** | ¥180-250/月 | ¥93/月 (节省 44-63%) |

## 🔄 迁移指南

### 从 Supabase 迁移

#### 1. 替换导入

```dart
// 之前
import 'package:supabase_flutter/supabase_flutter.dart';
final supabase = Supabase.instance.client;

// 之后
import 'core/services/backend_manager.dart';
// 使用全局实例 backend
```

#### 2. 更新查询

```dart
// 之前 (Supabase)
final trips = await supabase
    .from('trips')
    .select()
    .eq('status', 'planning')
    .execute();

// 之后 (Tencent Cloud)
final trips = await backend.database
    .from('trips')
    .select()
    .eq('status', 'planning')
    .get();
```

#### 3. 更新认证

```dart
// 之前 (Supabase)
final response = await supabase.auth.signUp(
  email: email,
  password: password,
);
final user = response.user;

// 之后 (Tencent Cloud)
final result = await backend.auth.signUp(
  email: email,
  password: password,
);
final user = result['user'];
```

#### 4. 更新存储

```dart
// 之前 (Supabase)
final path = await supabase.storage
    .from('avatars')
    .upload('user-id/avatar.jpg', file);

// 之后 (Cloudflare R2)
final url = await backend.storage.uploadAvatar(
  userId: 'user-id',
  filePath: file.path,
);
```

## 🛠️ 故障排除

### 数据库连接失败

```
❌ Database connection failed: Connection refused
```

**解决方案**：
1. 检查 `.env` 中的 `DB_HOST` 和 `DB_PORT`
2. 确认 Tencent Cloud PostgreSQL 实例正在运行
3. 检查防火墙规则允许你的 IP

### RLS 策略错误

```
❌ Query failed: new row violates row-level security policy
```

**解决方案**：
1. 确保用户已登录：`backend.auth.isAuthenticated`
2. 检查数据库 RLS 策略是否正确
3. 验证 `current_user_id()` 函数已创建

### R2 上传失败

```
❌ Upload failed: Access Denied
```

**解决方案**：
1. 验证 R2 凭证正确
2. 确认 bucket 存在
3. 检查 R2 访问策略

## 📖 参考资料

- [Tencent Cloud PostgreSQL 文档](https://cloud.tencent.com/document/product/409)
- [Cloudflare R2 文档](https://developers.cloudflare.com/r2/)
- [PostgreSQL postgres 包](https://pub.dev/packages/postgres)
- [Minio Dart 客户端](https://pub.dev/packages/minio)
- [JWT Dart 包](https://pub.dev/packages/dart_jsonwebtoken)

## 💡 最佳实践

1. **始终使用环境变量**：不要硬编码凭证
2. **错误处理**：使用 try-catch 包装所有数据库操作
3. **连接池**：不要在每次请求时创建新连接
4. **会话管理**：正确保存和恢复用户会话
5. **安全性**：使用强 JWT 密钥（至少 32 字符）

---

**需要帮助？** 查看 `main_backend.dart` 获取完整示例代码。

# Archive - 归档文件

## 📋 说明

此文件夹包含已弃用或被替代的旧版本文件，保留作为历史参考。

**归档日期**: 2026-02-24

---

## 📁 归档内容

### 1. `supabase/` - Supabase后端方案（已弃用）

**原因**: 项目从Supabase迁移到腾讯云PostgreSQL

**包含文件**:
- `migrations/001_initial_schema.sql` - 核心表结构（Supabase版）
- `migrations/002_row_level_security.sql` - RLS安全策略
- `migrations/003_storage_setup.sql` - 存储桶配置
- `seed.sql` - 种子数据
- `README.md` - 原始说明文档
- `DEPLOYMENT_GUIDE.md` - 部署指南

**创建日期**: 2025-10-23
**弃用日期**: 2026-01-25

**差异**:
- Supabase版本依赖`auth.users`表（Supabase内置认证）
- 腾讯云版本使用独立的`public.users`表（自建认证）
- 存储功能在腾讯云版本中改用Cloudflare R2

---

### 2. `docs/database_schema.sql` - 早期数据库设计文档

**原因**: 设计已在后续版本中完善和更新

**创建日期**: 2025-10-22
**被替代**: 2026-01-25腾讯云版本

**与最新版本的差异**:
- 缺少部分新增表（如`user_sessions`）
- 时间戳字段未使用`WITH TIME ZONE`
- 缺少部分优化的索引
- 缺少部分业务逻辑触发器

---

## 🔍 如何使用归档文件

### 查看历史演变

比较Supabase版本与腾讯云版本的差异：

```bash
# 比较主表结构
diff archive/supabase/migrations/001_initial_schema.sql \
     ../tencentcloud/migrations/001_initial_schema.sql

# 比较安全策略
diff archive/supabase/migrations/002_row_level_security.sql \
     ../tencentcloud/migrations/002_row_level_security.sql
```

### 迁移参考

如果需要从Supabase迁移到腾讯云，参考这些文件了解变更点：

**主要变更**:
1. 认证系统从`auth.users`改为`public.users`
2. 存储从Supabase Storage改为Cloudflare R2
3. 时间戳字段统一使用`TIMESTAMP WITH TIME ZONE`
4. 添加了`user_sessions`表用于JWT管理
5. 添加了`pgcrypto`扩展用于密码哈希

---

## ⚠️ 注意事项

1. **不要修改归档文件** - 这些文件仅供参考
2. **不要用于生产环境** - 归档方案已过时
3. **谨慎恢复** - 如需恢复旧方案，请先咨询团队

---

## 📚 最新文档位置

| 类型 | 最新位置 |
|------|----------|
| 主数据库Schema | `../tencentcloud/migrations/` |
| 地图翻译Schema | `../tencentcloud/tencentcloud_translation/` |
| 部署文档 | `../tencentcloud/README.md` |
| MVP进度 | `../mobile_app/MVP_PROGRESS_TRACKER.md` |

---

**归档人**: Claude
**归档日期**: 2026-02-24
**清理计划**: 3个月后（2026-05-24）可考虑删除

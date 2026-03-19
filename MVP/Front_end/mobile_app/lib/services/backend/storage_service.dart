import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../core/config/backend_config.dart';
import '../api_client.dart';

/// Storage Service for Tencent COS (Cloud Object Storage)
/// 使用 STS 临时凭证上传，避免客户端存储密钥
class StorageService {
  static StorageService? _instance;

  // Singleton pattern
  StorageService._();

  factory StorageService() {
    _instance ??= StorageService._();
    return _instance!;
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize storage service (无需初始化，按需获取 STS 凭证)
  Future<void> initialize() async {
    debugPrint('✅ COS Storage Service ready (STS on-demand)');
  }

  bool get isInitialized => true;

  // ============================================================================
  // UPLOAD METHODS (使用 STS 临时凭证)
  // ============================================================================

  /// 获取 STS 临时凭证
  Future<Map<String, dynamic>> _getSTSCredentials({
    required String objectPath,
    int durationSeconds = 1800, // 30分钟
  }) async {
    try {
      final result = await ApiClient.post(ApiClient.cosTokenUrl, {
        'object_path': objectPath,
        'duration_seconds': durationSeconds,
      });

      return {
        'credentials': result['credentials'],
        'upload_url': result['upload_url'],
      };
    } catch (e) {
      debugPrint('❌ 获取STS凭证失败: $e');
      rethrow;
    }
  }

  /// Upload a file from path
  Future<String> uploadFile({
    required String objectName,
    required String filePath,
    Map<String, String>? metadata,
  }) async {
    try {
      debugPrint('⬆️ Uploading file to COS: $objectName...');

      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File not found: $filePath');
      }

      final bytes = await file.readAsBytes();
      return await uploadBytes(
        objectName: objectName,
        bytes: bytes,
        contentType: _getContentType(path.extension(filePath)),
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      rethrow;
    }
  }

  /// Upload from bytes (推荐使用，支持 Web/Mobile)
  Future<String> uploadBytes({
    required String objectName,
    required Uint8List bytes,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      debugPrint('⬆️ Uploading ${bytes.length} bytes to $objectName...');

      // Step 1: 获取 STS 临时凭证和上传 URL
      final stsData = await _getSTSCredentials(objectPath: objectName);
      final uploadUrl = stsData['upload_url'] as String;

      // Step 2: 使用临时凭证上传（云函数已生成签名）
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType ?? 'application/octet-stream',
          if (metadata != null) ...metadata,
        },
        body: bytes,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final publicUrl = '${BackendConfig.cosStaticUrl}/$objectName';
        debugPrint('✅ File uploaded: $publicUrl');
        return publicUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      rethrow;
    }
  }

  /// Upload avatar image
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    final ext = path.extension(filePath);
    final objectName = 'avatars/$userId$ext';

    return await uploadFile(
      objectName: objectName,
      filePath: filePath,
      metadata: {
        'x-cos-meta-type': 'avatar',
        'x-cos-meta-user-id': userId,
      },
    );
  }

  /// Upload post image
  Future<String> uploadPostImage({
    required String userId,
    required String postId,
    required String filePath,
  }) async {
    final ext = path.extension(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final objectName = 'posts/$userId/$postId/$timestamp$ext';

    return await uploadFile(
      objectName: objectName,
      filePath: filePath,
      metadata: {
        'x-cos-meta-type': 'post_image',
        'x-cos-meta-user-id': userId,
        'x-cos-meta-post-id': postId,
      },
    );
  }

  /// Upload place photo
  Future<String> uploadPlacePhoto({
    required String placeId,
    required String filePath,
  }) async {
    final ext = path.extension(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final objectName = 'places/$placeId/$timestamp$ext';

    return await uploadFile(
      objectName: objectName,
      filePath: filePath,
      metadata: {
        'x-cos-meta-type': 'place_photo',
        'x-cos-meta-place-id': placeId,
      },
    );
  }

  /// Upload receipt photo (private bucket, 需要后端验证权限)
  Future<String> uploadReceipt({
    required String userId,
    required String expenseId,
    required String filePath,
  }) async {
    final ext = path.extension(filePath);
    final objectName = 'receipts/$userId/$expenseId$ext';

    return await uploadFile(
      objectName: objectName,
      filePath: filePath,
      metadata: {
        'x-cos-meta-type': 'receipt',
        'x-cos-meta-user-id': userId,
        'x-cos-meta-expense-id': expenseId,
      },
    );
  }

  // ============================================================================
  // DELETE METHODS (通过云函数删除，需要权限验证)
  // ============================================================================

  /// Delete a file (调用云函数)
  Future<void> deleteFile({
    required String objectName,
  }) async {
    try {
      debugPrint('🗑️ Deleting $objectName...');

      await ApiClient.post(ApiClient.cosTokenUrl, {
        'action': 'delete',
        'object_path': objectName,
      });

      debugPrint('✅ File deleted');
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
      rethrow;
    }
  }

  /// Delete multiple files (批量删除)
  Future<void> deleteFiles({
    required List<String> objectNames,
  }) async {
    try {
      debugPrint('🗑️ Deleting ${objectNames.length} files...');

      await ApiClient.post(ApiClient.cosTokenUrl, {
        'action': 'batch_delete',
        'object_paths': objectNames,
      });

      debugPrint('✅ Files deleted');
    } catch (e) {
      debugPrint('❌ Batch delete failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get public URL for an object (静态资源公开访问)
  String getPublicUrl(String objectName) {
    return '${BackendConfig.cosStaticUrl}/$objectName';
  }
}

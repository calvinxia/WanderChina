import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:minio/minio.dart';
import 'package:path/path.dart' as path;
import '../../core/config/backend_config.dart';

/// Storage Service for Cloudflare R2
/// Replaces Supabase Storage
class StorageService {
  static StorageService? _instance;
  Minio? _client;

  // Singleton pattern
  StorageService._();

  factory StorageService() {
    _instance ??= StorageService._();
    return _instance!;
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize R2 client
  Future<void> initialize() async {
    if (_client != null) {
      debugPrint('⚠️ Storage already initialized');
      return;
    }

    try {
      debugPrint('🔌 Connecting to Cloudflare R2...');

      _client = Minio(
        endPoint: BackendConfig.r2Endpoint,
        accessKey: BackendConfig.r2AccessKeyId,
        secretKey: BackendConfig.r2SecretAccessKey,
        useSSL: true,
        enableTrace: kDebugMode,
      );

      // Verify connection by listing buckets
      await _client!.listBuckets();

      debugPrint('✅ R2 connected successfully');
      debugPrint('📍 Endpoint: ${BackendConfig.r2Endpoint}');
    } catch (e) {
      debugPrint('❌ R2 connection failed: $e');
      rethrow;
    }
  }

  /// Check if storage is initialized
  bool get isInitialized => _client != null;

  /// Get the Minio client
  Minio get client {
    if (_client == null) {
      throw Exception('Storage not initialized. Call initialize() first.');
    }
    return _client!;
  }

  // ============================================================================
  // UPLOAD METHODS
  // ============================================================================

  /// Upload a file from path
  Future<String> uploadFile({
    required String bucket,
    required String objectName,
    required String filePath,
    Map<String, String>? metadata,
  }) async {
    try {
      debugPrint('⬆️ Uploading file to $bucket/$objectName...');

      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File not found: $filePath');
      }

      await client.fPutObject(
        bucket,
        objectName,
        filePath,
        metadata: metadata,
      );

      final url = BackendConfig.getPublicUrl(bucket, objectName);
      debugPrint('✅ File uploaded: $url');

      return url;
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      rethrow;
    }
  }

  /// Upload from bytes (for web/mobile)
  Future<String> uploadBytes({
    required String bucket,
    required String objectName,
    required Uint8List bytes,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      debugPrint('⬆️ Uploading bytes to $bucket/$objectName...');

      await client.putObject(
        bucket,
        objectName,
        Stream.value(bytes),
        bytes.length,
        metadata: metadata,
        contentType: contentType,
      );

      final url = BackendConfig.getPublicUrl(bucket, objectName);
      debugPrint('✅ Bytes uploaded: $url');

      return url;
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
    final objectName = '$userId/avatar$ext';

    return await uploadFile(
      bucket: BackendConfig.avatarsBucket,
      objectName: objectName,
      filePath: filePath,
      metadata: {
        'Content-Type': _getContentType(ext),
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
    final objectName = '$userId/$postId/$timestamp$ext';

    return await uploadFile(
      bucket: BackendConfig.postImagesBucket,
      objectName: objectName,
      filePath: filePath,
      metadata: {
        'Content-Type': _getContentType(ext),
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
    final objectName = '$placeId/$timestamp$ext';

    return await uploadFile(
      bucket: BackendConfig.placePhotosBucket,
      objectName: objectName,
      filePath: filePath,
      metadata: {
        'Content-Type': _getContentType(ext),
      },
    );
  }

  /// Upload receipt photo (private)
  Future<String> uploadReceipt({
    required String userId,
    required String expenseId,
    required String filePath,
  }) async {
    final ext = path.extension(filePath);
    final objectName = '$userId/$expenseId$ext';

    return await uploadFile(
      bucket: BackendConfig.receiptsBucket,
      objectName: objectName,
      filePath: filePath,
      metadata: {
        'Content-Type': _getContentType(ext),
      },
    );
  }

  // ============================================================================
  // DOWNLOAD METHODS
  // ============================================================================

  /// Download a file
  Future<void> downloadFile({
    required String bucket,
    required String objectName,
    required String destinationPath,
  }) async {
    try {
      debugPrint('⬇️ Downloading $bucket/$objectName...');

      await client.fGetObject(bucket, objectName, destinationPath);

      debugPrint('✅ File downloaded: $destinationPath');
    } catch (e) {
      debugPrint('❌ Download failed: $e');
      rethrow;
    }
  }

  /// Get file as bytes
  Future<Uint8List> getBytes({
    required String bucket,
    required String objectName,
  }) async {
    try {
      final stream = await client.getObject(bucket, objectName);
      final bytes = await stream.expand((chunk) => chunk).toList();
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('❌ Get bytes failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // DELETE METHODS
  // ============================================================================

  /// Delete a file
  Future<void> deleteFile({
    required String bucket,
    required String objectName,
  }) async {
    try {
      debugPrint('🗑️ Deleting $bucket/$objectName...');

      await client.removeObject(bucket, objectName);

      debugPrint('✅ File deleted');
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
      rethrow;
    }
  }

  /// Delete multiple files
  Future<void> deleteFiles({
    required String bucket,
    required List<String> objectNames,
  }) async {
    try {
      debugPrint('🗑️ Deleting ${objectNames.length} files...');

      await client.removeObjects(bucket, objectNames);

      debugPrint('✅ Files deleted');
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // LIST METHODS
  // ============================================================================

  /// List objects in a bucket with prefix
  Future<List<String>> listObjects({
    required String bucket,
    String? prefix,
  }) async {
    try {
      final objects = await client.listObjects(bucket, prefix: prefix).toList();
      return objects.map((obj) => obj.key ?? '').toList();
    } catch (e) {
      debugPrint('❌ List objects failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // BUCKET MANAGEMENT
  // ============================================================================

  /// Create all required buckets
  Future<void> createBuckets() async {
    final buckets = [
      BackendConfig.avatarsBucket,
      BackendConfig.postImagesBucket,
      BackendConfig.placePhotosBucket,
      BackendConfig.receiptsBucket,
      BackendConfig.badgesBucket,
      BackendConfig.mapTilesBucket,
    ];

    for (final bucket in buckets) {
      try {
        final exists = await client.bucketExists(bucket);
        if (!exists) {
          await client.makeBucket(bucket);
          debugPrint('✅ Bucket created: $bucket');
        }
      } catch (e) {
        debugPrint('❌ Failed to create bucket $bucket: $e');
      }
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
      default:
        return 'application/octet-stream';
    }
  }

  /// Get public URL for an object
  String getPublicUrl(String bucket, String objectName) {
    return BackendConfig.getPublicUrl(bucket, objectName);
  }
}

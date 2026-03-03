/// Backend Configuration for Tencent Cloud + Cloudflare R2
/// Replaces Supabase configuration
class BackendConfig {
  // ============================================================================
  // DATABASE CONFIGURATION (Tencent Cloud PostgreSQL)
  // ============================================================================

  static const String databaseHost = String.fromEnvironment(
    'DB_HOST',
    defaultValue: 'your-tencentcloud-host.com',
  );

  static const int databasePort = int.fromEnvironment(
    'DB_PORT',
    defaultValue: 5432,
  );

  static const String databaseName = String.fromEnvironment(
    'DB_NAME',
    defaultValue: 'wanderchina',
  );

  static const String databaseUsername = String.fromEnvironment(
    'DB_USERNAME',
    defaultValue: 'postgres',
  );

  static const String databasePassword = String.fromEnvironment(
    'DB_PASSWORD',
    defaultValue: '',
  );

  static const bool databaseSSL = bool.fromEnvironment(
    'DB_SSL',
    defaultValue: true,
  );

  // Connection pool settings
  static const int minConnections = 2;
  static const int maxConnections = 10;
  static const Duration connectionTimeout = Duration(seconds: 30);

  // ============================================================================
  // STORAGE CONFIGURATION (Cloudflare R2)
  // ============================================================================

  static const String r2AccountId = String.fromEnvironment(
    'R2_ACCOUNT_ID',
    defaultValue: '',
  );

  static const String r2AccessKeyId = String.fromEnvironment(
    'R2_ACCESS_KEY_ID',
    defaultValue: '',
  );

  static const String r2SecretAccessKey = String.fromEnvironment(
    'R2_SECRET_ACCESS_KEY',
    defaultValue: '',
  );

  // R2 endpoint format: https://<account_id>.r2.cloudflarestorage.com
  static String get r2Endpoint => '$r2AccountId.r2.cloudflarestorage.com';

  // Public domain for accessing files (via Cloudflare CDN)
  static const String r2PublicDomain = String.fromEnvironment(
    'R2_PUBLIC_DOMAIN',
    defaultValue: 'https://cdn.wanderchina.app',
  );

  // R2 Buckets (matching database storage structure)
  static const String avatarsBucket = 'avatars';
  static const String postImagesBucket = 'post-images';
  static const String placePhotosBucket = 'place-photos';
  static const String receiptsBucket = 'receipts';
  static const String badgesBucket = 'badges';
  static const String mapTilesBucket = 'map-tiles';

  // ============================================================================
  // JWT CONFIGURATION
  // ============================================================================

  static const String jwtSecret = String.fromEnvironment(
    'JWT_SECRET',
    defaultValue: 'your-super-secret-jwt-key-change-in-production',
  );

  static const Duration jwtExpiration = Duration(days: 7);
  static const String jwtIssuer = 'wanderchina.app';

  // ============================================================================
  // API CONFIGURATION
  // ============================================================================

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.wanderchina.app',
  );

  // ============================================================================
  // TRANSLATION & VOICE API CONFIGURATION
  // ============================================================================

  // DeepSeek API for translation
  static const String deepseekApiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: '',
  );

  // Baidu Voice API for ASR (Speech Recognition) and TTS (Text-to-Speech)
  static const String baiduApiKey = String.fromEnvironment(
    'BAIDU_API_KEY',
    defaultValue: '',
  );

  static const String baiduSecretKey = String.fromEnvironment(
    'BAIDU_SECRET_KEY',
    defaultValue: '',
  );

  // ============================================================================
  // VALIDATION
  // ============================================================================

  static bool get isDatabaseConfigured {
    return databaseHost.isNotEmpty &&
        databasePassword.isNotEmpty &&
        !databaseHost.contains('your-tencentcloud');
  }

  static bool get isStorageConfigured {
    return r2AccountId.isNotEmpty &&
        r2AccessKeyId.isNotEmpty &&
        r2SecretAccessKey.isNotEmpty;
  }

  static bool get isFullyConfigured {
    return isDatabaseConfigured && isStorageConfigured;
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get database connection URI
  static String get databaseUri {
    final sslMode = databaseSSL ? 'require' : 'prefer';
    return 'postgresql://$databaseUsername:$databasePassword@$databaseHost:$databasePort/$databaseName?sslmode=$sslMode';
  }

  /// Get public URL for a storage object
  static String getPublicUrl(String bucket, String path) {
    return '$r2PublicDomain/$bucket/$path';
  }

  /// Print configuration status (for debugging)
  static void printStatus() {
    print('=== Backend Configuration ===');
    print('Database: ${isDatabaseConfigured ? "✅" : "❌"} $databaseHost:$databasePort');
    print('Storage:  ${isStorageConfigured ? "✅" : "❌"} R2 ($r2AccountId)');
    print('JWT:      ✅ Configured');
    print('============================');
  }
}

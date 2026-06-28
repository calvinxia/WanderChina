# ============================================================================
# WanderChina ProGuard / R8 Rules
# 2026-05-28
#
# 根因记录:
#   AGP 8.9.1 在 release 构建中默认启用 R8 (minifyReleaseWithR8),
#   即使 build.gradle 未显式声明 minifyEnabled true。
#   高德 SDK 大量类通过 native 层 (libAMapSDK_MAP_*.so) 反射调用,
#   R8 静态分析无法识别引用关系,误判为无用代码并删除,
#   导致运行时 ClassNotFoundException: com.autonavi.base.amap.mapcore.ClassTools
#   -> native SIGABRT 崩溃 (地图渲染时 onSurfaceCreated 回调)。
#   修复:保留所有高德相关类。
# ============================================================================

# ---------------------------------------------------------------------------
# 高德地图 SDK (AMap) —— 官方推荐 keep 规则
# ---------------------------------------------------------------------------
-keep class com.amap.api.**  { *; }
-keep class com.amap.api.maps.**  { *; }
-keep class com.amap.api.maps2d.**  { *; }
-keep class com.amap.api.mapcore.**  { *; }
-keep class com.amap.api.services.**  { *; }
-keep class com.amap.api.location.**  { *; }
-keep class com.amap.api.fence.**  { *; }
-keep class com.amap.api.navi.**  { *; }
-keep class com.amap.api.trace.**  { *; }
-keep class com.amap.api.col.**  { *; }

-keep class com.autonavi.**  { *; }
-keep class com.autonavi.base.**  { *; }
-keep class com.autonavi.base.amap.mapcore.**  { *; }
-keep class com.autonavi.amap.mapcore.**  { *; }
-keep class com.autonavi.aps.amapapi.model.**  { *; }

-keep class com.loc.**  { *; }

-dontwarn com.amap.api.**
-dontwarn com.autonavi.**
-dontwarn com.loc.**

# 高德通过反射调用的 native 回调类,必须保留成员
-keepclassmembers class com.autonavi.** { *; }
-keepclassmembers class com.amap.api.** { *; }

# ---------------------------------------------------------------------------
# Flutter
# ---------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ---------------------------------------------------------------------------
# Sentry
# ---------------------------------------------------------------------------
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# ---------------------------------------------------------------------------
# Google ML Kit / Barcode (mobile_scanner)
# ---------------------------------------------------------------------------
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.libraries.barhopper.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# ---------------------------------------------------------------------------
# 通用保留规则
# ---------------------------------------------------------------------------
# 保留 native 方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留枚举
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留 Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# 保留注解、签名、内部类信息(反射依赖)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable

# ---------------------------------------------------------------------------
# Google Sign-In / Play Services Auth
# ---------------------------------------------------------------------------
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.**

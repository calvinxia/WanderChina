#!/bin/bash
# ============================================================================
# fix_amap_plugin.sh
# ----------------------------------------------------------------------------
# 修复 amap_flutter_location 3.0.0 老插件与 AGP 8.x 的兼容问题。
#
# 背景:该插件是 2019 年的老版本,不兼容 AGP 8.9.1:
#   1. android/build.gradle 缺 namespace(已在项目级 build.gradle 注入解决)
#   2. android/src/main/AndroidManifest.xml 用了过时的 package= 属性,
#      AGP 8 不允许,需删除。
#
# 该脚本删除 manifest 的 package 属性。
#
# 用法:每次 `flutter clean` + `flutter pub get` 后,打包前运行一次:
#   bash fix_amap_plugin.sh
#
# TODO(v1.1): 升级或替换 amap_flutter_location,根治此技术债。
# ============================================================================

set -e

PLUGIN_MANIFEST="$HOME/.pub-cache/hosted/pub.dev/amap_flutter_location-3.0.0/android/src/main/AndroidManifest.xml"

if [ ! -f "$PLUGIN_MANIFEST" ]; then
    echo "⚠️  未找到插件 manifest,可能版本号变了或插件未安装:"
    echo "    $PLUGIN_MANIFEST"
    exit 1
fi

# 检查是否还有 package 属性
if grep -q 'package="com.amap.flutter.location"' "$PLUGIN_MANIFEST"; then
    # 删除 package 属性所在的整行内容(用 sed 删除 package="..." 这个属性)
    # 兼容 macOS 的 sed(需要 -i '')
    sed -i '' 's/[[:space:]]*package="com.amap.flutter.location"//' "$PLUGIN_MANIFEST"
    echo "✅ 已删除 amap_flutter_location manifest 的 package 属性"
    echo "    修复后内容:"
    cat "$PLUGIN_MANIFEST"
else
    echo "✅ amap_flutter_location manifest 已无 package 属性,无需修复"
fi

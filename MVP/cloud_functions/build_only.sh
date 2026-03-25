#!/bin/bash
# ============================================================================
# WanderChina 云函数打包脚本（纯打包，不修改代码）
# 用法: cd cloud_functions && bash build_only.sh
# ============================================================================

set -e

DIST_DIR="dist"
SHARED_DIR="shared"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

PIP_ARGS="--platform manylinux2014_x86_64 --implementation cp --python-version 3.9 --only-binary=:all: --quiet --no-cache-dir"

build_func() {
    local func_name=$1
    shift
    local deps="$@"

    echo "📦 $func_name"

    local BUILD_DIR="/tmp/scf_build_${func_name}"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR/shared"

    cp "${func_name}/index.py" "$BUILD_DIR/"
    cp "$SHARED_DIR/db_helper.py" "$BUILD_DIR/shared/"
    touch "$BUILD_DIR/shared/__init__.py"

    if [ "$func_name" = "get_cos_token" ]; then
        pip install $deps "urllib3<2" -t "$BUILD_DIR" --quiet --no-cache-dir
    else
        pip install $deps -t "$BUILD_DIR" $PIP_ARGS
    fi

    cd "$BUILD_DIR"
    zip -r -q "${func_name}.zip" .
    cd - > /dev/null

    mv "$BUILD_DIR/${func_name}.zip" "$DIST_DIR/"
    rm -rf "$BUILD_DIR"

    echo "  ✅ $DIST_DIR/${func_name}.zip"
}

build_func deepseek_translate "requests==2.31.0" "urllib3<2"
build_func baidu_voice_asr "requests==2.31.0" "urllib3<2"
build_func baidu_voice_tts "requests==2.31.0" "urllib3<2"
build_func get_cos_token "tencentcloud-sdk-python-sts==3.0.1000"
build_func translate_db_write "psycopg2-binary==2.9.9" "redis==5.0.1"
build_func get_nearby_pois "psycopg2-binary==2.9.9" "redis==5.0.1"
build_func user_auth "psycopg2-binary==2.9.9" "redis==5.0.1"
build_func create_trip "psycopg2-binary==2.9.9"
build_func search_poi "psycopg2-binary==2.9.9" "redis==5.0.1"
build_func route_plan "requests==2.31.0" "urllib3<2"

echo ""
echo "========================================"
echo "✅ 全部打包完成"
echo "========================================"
ls -lh "$DIST_DIR/"

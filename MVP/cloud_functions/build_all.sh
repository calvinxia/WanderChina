#!/bin/bash
# ============================================================================
# WanderChina 云函数打包脚本
# 用法: cd cloud_functions && bash build_all.sh
# 输出: dist/ 目录下 8 个 zip 包，直接上传 SCF 控制台
# ============================================================================

set -e

DIST_DIR="dist"
SHARED_DIR="shared"

# 清理旧构建
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# ===== 公网函数（不需要 db 依赖的用 requests，需要 db 的加 psycopg2 + redis）=====

# 函数列表: 目录名 | 是否需要 shared/db_helper.py | 额外依赖
FUNCTIONS=(
    "deepseek_translate|yes|requests"
    "baidu_voice_asr|yes|requests"
    "baidu_voice_tts|yes|requests"
    "get_cos_token|yes|tencentcloud-sdk-python-sts"
    "translate_db_write|yes|psycopg2-binary,redis"
    "get_nearby_pois|yes|psycopg2-binary,redis"
    "user_auth|yes|psycopg2-binary,redis"
    "create_trip|yes|psycopg2-binary,redis"
)

for entry in "${FUNCTIONS[@]}"; do
    IFS='|' read -r func_name needs_shared deps <<< "$entry"

    echo "========================================"
    echo "📦 Packaging: $func_name"
    echo "========================================"

    # 创建临时构建目录
    BUILD_DIR="/tmp/scf_build_${func_name}"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    # 复制函数代码
    cp "${func_name}/index.py" "$BUILD_DIR/"

    # 复制 shared 模块
    if [ "$needs_shared" = "yes" ] && [ -d "$SHARED_DIR" ]; then
        mkdir -p "$BUILD_DIR/shared"
        cp "$SHARED_DIR/db_helper.py" "$BUILD_DIR/shared/"
        # 创建 __init__.py 确保 Python 能识别为包
        touch "$BUILD_DIR/shared/__init__.py"
    fi

    # 安装依赖到构建目录
    IFS=',' read -ra DEP_LIST <<< "$deps"
    for dep in "${DEP_LIST[@]}"; do
        echo "  Installing: $dep"
        pip install "$dep" -t "$BUILD_DIR" --quiet --no-cache-dir
    done

    # 打包 zip
    cd "$BUILD_DIR"
    zip -r -q "${func_name}.zip" .
    cd - > /dev/null

    # 移动到 dist
    mv "$BUILD_DIR/${func_name}.zip" "$DIST_DIR/"

    # 清理
    rm -rf "$BUILD_DIR"

    echo "  ✅ $DIST_DIR/${func_name}.zip"
    echo ""
done

# 显示结果
echo "========================================"
echo "✅ 全部打包完成"
echo "========================================"
ls -lh "$DIST_DIR/"
echo ""
echo "下一步: 在 SCF 控制台逐个上传 zip 包"

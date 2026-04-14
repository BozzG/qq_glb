#!/bin/bash
# 清理旧构建并重新构建 iOS
# 用法: ./build_ios.sh [--no-clean] [--release]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

BUILD_MODE="debug"

# 解析参数
SKIP_CLEAN=false
for arg in "$@"; do
  case "$arg" in
    --no-clean)  SKIP_CLEAN=true ;;
    --release)   BUILD_MODE="release" ;;
    *)           echo "未知参数: $arg"; exit 1 ;;
  esac
done

# 清理旧构建
if [ "$SKIP_CLEAN" = false ]; then
  echo "==> 清理旧构建..."
  flutter clean
  echo "==> 获取依赖..."
  flutter pub get
else
  echo "==> 跳过清理"
fi

# 安装 iOS 依赖
echo "==> 安装 CocoaPods 依赖..."
cd ios
pod install
cd ..

# 构建
if [ "$BUILD_MODE" = "release" ]; then
  echo "==> 构建 iOS Release..."
  flutter build ios --release
else
  echo "==> 构建 iOS Debug..."
  flutter build ios --debug
fi

echo "==> 构建完成！输出目录: build/ios/iphoneos/"

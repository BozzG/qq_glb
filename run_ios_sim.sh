#!/bin/bash
# 清理构建并在 iOS 仿真器上运行
# 用法: ./run_ios_sim.sh [--no-clean]

set -e

DEVICE_ID="9D3347BB-CB8B-483C-86A9-7F7FB13874A2"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_DIR"

# 是否跳过清理
if [ "$1" != "--no-clean" ]; then
  echo "==> 清理构建..."
  flutter clean
  echo "==> 获取依赖..."
  flutter pub get
else
  echo "==> 跳过清理，直接运行"
fi

# 启动仿真器
echo "==> 启动 iOS 仿真器..."
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
open -a Simulator

# 运行应用
echo "==> 运行 Flutter 应用..."
flutter run -d "$DEVICE_ID"

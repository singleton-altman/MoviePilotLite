#!/usr/bin/env bash
set -e
FLUTTER="/Users/junchen/fvm/versions/custom_3.35.7_ohos/bin/flutter"
MODE="${1:-debug}"
cd "$(dirname "$0")/.."
"$FLUTTER" build hap --"$MODE"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Missing dependency: gh (GitHub CLI)" >&2
  exit 2
fi

PUBSPEC_YAML="${PUBSPEC_YAML:-pubspec.yaml}"

if [[ ! -f "${PUBSPEC_YAML}" ]]; then
  echo "pubspec.yaml not found: ${PUBSPEC_YAML}" >&2
  exit 1
fi

VERSION="$(grep '^version:' "${PUBSPEC_YAML}" | sed 's/version: *//' | sed 's/+.*//' | tr -d ' ')"
BUILD_DATE="$(date +%Y-%m-%d)"
RELEASE_NAME="v${VERSION}-${BUILD_DATE}"
TAG_NAME="release-${RELEASE_NAME}"

if command -v fvm >/dev/null 2>&1; then
  FLUTTER_CMD=(fvm flutter)
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER_CMD=(flutter)
else
  echo "Missing dependency: fvm or flutter" >&2
  exit 2
fi

HAP_DIR="build/ohos/hap"
mkdir -p "${HAP_DIR}"

shopt -s nullglob
OLD_HAPS=("${HAP_DIR}"/*.hap)
shopt -u nullglob
if (( ${#OLD_HAPS[@]} > 0 )); then
  rm -f "${OLD_HAPS[@]}"
fi

("${FLUTTER_CMD[@]}" build hap --debug)

shopt -s nullglob
HAPS=("${HAP_DIR}"/*.hap)
shopt -u nullglob

if (( ${#HAPS[@]} == 0 )); then
  echo "No .hap files found in: ${HAP_DIR}" >&2
  exit 1
fi

TITLE="ohos-${RELEASE_NAME}"

if gh release view "${TAG_NAME}" >/dev/null 2>&1; then
  gh release edit "${TAG_NAME}" --title "${TITLE}"
else
  gh release create "${TAG_NAME}" --title "${TITLE}" --notes ""
fi

gh release upload "${TAG_NAME}" "${HAPS[@]}" --clobber

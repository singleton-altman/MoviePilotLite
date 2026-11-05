#!/bin/sh
# Xcode Cloud 构建完成后，将 IPA 上传到 GitHub Release
# 需在 Xcode Cloud 的 Environment 中配置 GITHUB_TOKEN（Secret）

set -e

# 仅在 Archive 且构建成功时上传
if [ -z "$CI_APP_STORE_SIGNED_APP_PATH" ] || [ ! -d "$CI_APP_STORE_SIGNED_APP_PATH" ]; then
  echo "No App Store signed app path, skip GitHub Release upload."
  exit 0
fi

# 查找 IPA 文件
IPA=$(find "$CI_APP_STORE_SIGNED_APP_PATH" -name "*.ipa" 2>/dev/null | head -1)
if [ -z "$IPA" ] || [ ! -f "$IPA" ]; then
  echo "No IPA found in $CI_APP_STORE_SIGNED_APP_PATH"
  exit 0
fi

# 需配置 GITHUB_TOKEN
if [ -z "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN not set, skip GitHub Release upload."
  exit 0
fi

# 仓库：从环境变量或 git remote 解析
REPO="${GITHUB_REPO}"
if [ -z "$REPO" ]; then
  ORIGIN=$(git -C "$CI_PRIMARY_REPOSITORY_PATH" remote get-url origin 2>/dev/null || true)
  if echo "$ORIGIN" | grep -q "github.com"; then
    REPO=$(echo "$ORIGIN" | sed -E 's|.*github\.com[:/]([^/]+/[^/]+?)(\.git)?$|\1|')
  fi
fi
if [ -z "$REPO" ]; then
  echo "Could not determine GitHub repo, set GITHUB_REPO (e.g. owner/repo)"
  exit 0
fi

# 版本与 tag
VERSION=$(grep '^version:' "$CI_PRIMARY_REPOSITORY_PATH/pubspec.yaml" 2>/dev/null | sed 's/version: *//' | sed 's/+.*//' | tr -d ' ' || echo "1.0.0")
RELEASE_NAME="ios-$(date +%Y-%m-%d-%H-%M)-$VERSION"
TAG="release-$RELEASE_NAME"

echo "Uploading to GitHub Release: $TAG"

# 创建 Release
RESP=$(curl -s -w "\n%{http_code}" -X POST "https://api.github.com/repos/$REPO/releases" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "{
    \"tag_name\": \"$TAG\",
    \"name\": \"$RELEASE_NAME\",
    \"body\": \"MoviePilot iOS Release\\n- Build: $RELEASE_NAME\\n- Version: $VERSION\"
  }")
HTTP_CODE=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | sed '$d')
if [ "$HTTP_CODE" -ne 201 ]; then
  echo "Failed to create release (HTTP $HTTP_CODE): $BODY"
  exit 1
fi
UPLOAD_URL=$(echo "$BODY" | grep -o '"upload_url": "[^"]*' | cut -d'"' -f4 | sed 's/{?name,label}/?name=MoviePilot.ipa/')

# 上传 IPA
UPLOAD_RESULT=$(curl -s -w "\n%{http_code}" -X POST "$UPLOAD_URL" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @"$IPA")
UPLOAD_HTTP=$(echo "$UPLOAD_RESULT" | tail -1)
if [ "$UPLOAD_HTTP" -ne 201 ]; then
  echo "Failed to upload IPA (HTTP $UPLOAD_HTTP)"
  exit 1
fi

echo "Successfully uploaded to https://github.com/$REPO/releases/tag/$TAG"

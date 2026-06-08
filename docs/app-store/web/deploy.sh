#!/bin/bash
# 把 privacy.html / support.html / index.html 发布到 GitHub Pages（gh-pages 分支）
# 用法：bash deploy.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="git@github.com:chenyuxiaojin/DropKit.git"

TMP="$(mktemp -d)"
cp "$SCRIPT_DIR/privacy.html" "$SCRIPT_DIR/support.html" "$SCRIPT_DIR/index.html" "$TMP/"
cd "$TMP"
git init -q
git checkout -q -b gh-pages
git add -A
git commit -q -m "Deploy DropKit pages to GitHub Pages"
git push -q --force "$REPO" gh-pages
cd / && rm -rf "$TMP"

echo "✅ 已发布到 GitHub Pages（约 1 分钟后生效）："
echo "   隐私政策: https://chenyuxiaojin.github.io/DropKit/privacy.html"
echo "   技术支持: https://chenyuxiaojin.github.io/DropKit/support.html"

#!/bin/bash
# 部署 DropKit 隐私政策页 + 技术支持页到服务器
# 与 homepage 同一台机器；放到 /opt/homepage/dropkit/ 下
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER="root@107.172.86.147"
KEY="$HOME/.ssh/id_ed25519"
REMOTE_DIR="/opt/homepage/dropkit"

echo "📁 创建远程目录 $REMOTE_DIR ..."
ssh -i "$KEY" "$SERVER" "mkdir -p $REMOTE_DIR" || { echo "❌ 无法连接服务器（检查代理/VPN 是否拦了 SSH）"; exit 1; }

echo "📤 上传 privacy.html / support.html ..."
scp -i "$KEY" "$SCRIPT_DIR/privacy.html" "$SCRIPT_DIR/support.html" "$SERVER:$REMOTE_DIR/"

if [ $? -eq 0 ]; then
    echo "✅ 部署成功！"
    echo "   隐私政策: https://xiaochens.com/dropkit/privacy.html"
    echo "   技术支持: https://xiaochens.com/dropkit/support.html"
    echo "   （若打不开，确认 xiaochens.com 的网站根目录是否为 /opt/homepage）"
else
    echo "❌ 上传失败"
    exit 1
fi

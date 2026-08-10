#!/bin/bash
set -e

# ... дальше весь остальной скрипт как был
cat > /usr/local/xray/config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${PORT:-8443},
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${VLESS_UUID}", "flow": "xtls-rprx-vision" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "www.microsoft.com:443",
          "serverNames": ["www.microsoft.com"],
          "privateKey": "${VLESS_PRIVATE_KEY}",
          "shortIds": ["${VLESS_SID}"]
        }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

echo "[start.sh] Валидирую конфиг..."
/usr/local/xray/xray run -test -c /usr/local/xray/config.json

echo "[start.sh] Запускаю Xray-сервер на порту ${PORT:-8443}..."
exec /usr/local/xray/xray run -c /usr/local/xray/config.json

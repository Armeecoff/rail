#!/bin/bash
cat > /usr/local/xray/config.json <<EOF
{
  "inbounds": [{
    "port": 1080,
    "listen": "127.0.0.1",
    "protocol": "socks",
    "settings": {"auth": "noauth", "udp": true}
  }],
  "outbounds": [{
    "protocol": "vless",
    "settings": {
      "vnext": [{
        "address": "${VLESS_HOST}",
        "port": ${VLESS_PORT},
        "users": [{"id": "${VLESS_UUID}", "encryption": "none", "flow": "xtls-rprx-vision"}]
      }]
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "serverName": "${VLESS_SNI}",
        "fingerprint": "chrome",
        "publicKey": "${VLESS_PBK}",
        "shortId": ""
      }
    }
  }]
}
EOF

/usr/local/xray/xray run -c /usr/local/xray/config.json &

sleep 3

python parser.py

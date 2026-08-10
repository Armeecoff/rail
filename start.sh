#!/bin/bash
set -e

# Собираем конфиг Xray-клиента из переменных окружения Railway
cat > /usr/local/xray/config.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "${VLESS_HOST}",
            "port": ${VLESS_PORT},
            "users": [
              {
                "id": "${VLESS_UUID}",
                "encryption": "none",
                "flow": "xtls-rprx-vision"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "serverName": "${VLESS_SNI}",
          "fingerprint": "${VLESS_FP}",
          "publicKey": "${VLESS_PBK}",
          "shortId": "${VLESS_SID}"
        }
      }
    }
  ]
}
EOF

echo "[start.sh] Запускаю Xray-клиент..."
/usr/local/xray/xray run -c /usr/local/xray/config.json &
XRAY_PID=$!

# Ждём, пока SOCKS5 реально поднимется, вместо фиксированного sleep
echo "[start.sh] Жду поднятия SOCKS5 на 127.0.0.1:1080..."
for i in $(seq 1 15); do
    if (echo > /dev/tcp/127.0.0.1/1080) 2>/dev/null; then
        echo "[start.sh] SOCKS5 доступен."
        break
    fi
    if [ "$i" -eq 15 ]; then
        echo "[start.sh] ОШИБКА: SOCKS5 не поднялся за 15 секунд, Xray мог не законнектиться к VLESS-серверу."
        kill $XRAY_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

# Проверяем, что через прокси реально виден интернет (а не просто открыт порт)
echo "[start.sh] Проверяю реальную доступность через прокси..."
if ! curl -s --max-time 10 --socks5-hostname 127.0.0.1:1080 https://api.telegram.org > /dev/null; then
    echo "[start.sh] ОШИБКА: прокси открыт, но трафик через VLESS-сервер не проходит (проверь UUID/ключи/бан по IP)."
    kill $XRAY_PID 2>/dev/null || true
    exit 1
fi
echo "[start.sh] Прокси рабочий, запускаю парсер."

# Если Xray внезапно упадёт — контейнер должен упасть целиком, чтобы Railway его перезапустил
( wait $XRAY_PID; echo "[start.sh] Xray неожиданно завершился!"; kill -TERM $$ ) &

python parser.py

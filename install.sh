#!/data/data/com.termux/files/usr/bin/bash
set -e
echo "▶ Установка TG WS Proxy для Termux..."

DEBIAN_FRONTEND=noninteractive pkg update -y
pkg install -y python python-cryptography git
pkg install -y python-psutil 2>/dev/null || true

pip install "httpx[http2]" certifi

cd "$HOME"
if [ -d tg-ws-proxy ]; then
  git -C tg-ws-proxy pull
else
  git clone https://github.com/Flowseal/tg-ws-proxy
fi

python -c "import cryptography, httpx, h2, certifi" \
  || { echo "❌ Не поставились зависимости"; exit 1; }

cat > "$PREFIX/bin/tgp" << 'LAUNCH'
#!/data/data/com.termux/files/usr/bin/bash
HOST=127.0.0.1; PORT=1443
DIR=$HOME/tg-ws-proxy
SF=$HOME/.tgproxy_secret
[ -f "$SF" ] || head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$SF"
SECRET=$(cat "$SF")
LINK="tg://proxy?server=$HOST&port=$PORT&secret=$SECRET"

run() {
  cd "$DIR" && PYTHONPATH="$DIR" python -c \
    "import sys; from proxy.tg_ws_proxy import main; sys.argv[0]='tg-ws-proxy'; main()" "$@"
}

case "$1" in
  stop)   pkill -f proxy.tg_ws_proxy && echo "Остановлен" || echo "Не запущен"; exit;;
  link)   termux-open-url "$LINK"; exit;;
  update) git -C "$DIR" pull; exit;;
esac

clear
echo "╔════════════════════════════╗"
echo "║       TG WS PROXY 🚀       ║"
echo "╚════════════════════════════╝"
echo
echo "Настройки Telegram (MTProto):"
echo "  Сервер: $HOST"
echo "  Порт:   $PORT"
echo "  Secret: $SECRET"
echo
echo "Быстрое подключение:"
echo "$LINK"
echo
echo "Команды: tgp bg | tgp stop | tgp link | tgp update"
echo "────────────────────────────"
termux-wake-lock 2>/dev/null

if [ "$1" = "bg" ]; then
  nohup bash -c "cd '$DIR' && PYTHONPATH='$DIR' python -c \"import sys; from proxy.tg_ws_proxy import main; main()\" --host $HOST --port $PORT --secret $SECRET --log-file $HOME/tgproxy.log" > /dev/null 2>&1 &
  echo "Запущен в фоне"
else
  run --host "$HOST" --port "$PORT" --secret "$SECRET"
fi
LAUNCH
chmod +x "$PREFIX/bin/tgp"

echo
echo "✅ Готово! Запуск: tgp"
echo " бурмалда Марк "

#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "=== TG WS Proxy для Termux ==="

# Проверка Termux
if [ -z "$PREFIX" ]; then
    echo "Ошибка: запусти скрипт в Termux"
    exit 1
fi

# Установка зависимостей
pkg update -y
pkg install -y python git

# Скачивание оригинального проекта
if [ -d "$HOME/tg-ws-proxy/.git" ]; then
    git -C "$HOME/tg-ws-proxy" pull
else
    git clone https://github.com/Flowseal/tg-ws-proxy.git "$HOME/tg-ws-proxy"
fi

# Установка Python-пакета
python -m pip install -e "$HOME/tg-ws-proxy"

# Создание команды запуска
cat > "$PREFIX/bin/tgp" <<'SCRIPT'
#!/data/data/com.termux/files/usr/bin/bash

DIR="$HOME/tg-ws-proxy"
PIDFILE="$HOME/.tgproxy.pid"
LOGFILE="$HOME/.tgproxy.log"

case "$1" in
    stop)
        if [ -f "$PIDFILE" ]; then
            kill "$(cat "$PIDFILE")" 2>/dev/null || true
            rm -f "$PIDFILE"
            echo "Прокси остановлен"
        else
            echo "Прокси не запущен"
        fi
        ;;
    bg)
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            echo "Прокси уже запущен"
            exit 0
        fi
        nohup tg-ws-proxy --host 127.0.0.1 --port 1443 > "$LOGFILE" 2>&1 &
        echo $! > "$PIDFILE"
        echo "Прокси запущен в фоне"
        echo "Лог: $LOGFILE"
        ;;
    update)
        git -C "$DIR" pull &&
        python -m pip install -e "$DIR"
        ;;
    link)
        echo "Проверь настройки и лог запуска:"
        cat "$LOGFILE" 2>/dev/null || true
        ;;
    *)
        cd "$DIR"
        exec tg-ws-proxy --host 127.0.0.1 --port 1443
        ;;
esac
SCRIPT

chmod +x "$PREFIX/bin/tgp"

echo ""
echo "Установка завершена!"
echo "Для запуска введи: tgp"

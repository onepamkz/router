#!/usr/bin/env bash
set -euo pipefail

# ── Настройки ────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/onepamkz/router.git"
DEPLOY_DIR="/opt/one-pam"
COMPOSE="docker compose"

# ── Цвета ────────────────────────────────────────────────────────────────────
info()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[1;32m[ OK ]\033[0m  $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
die()   { echo -e "\033[1;31m[ERR ]\033[0m  $*" >&2; exit 1; }

# ── 1. Docker ─────────────────────────────────────────────────────────────────
install_docker() {
  info "Устанавливаю Docker..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker "$USER" || true
  ok "Docker установлен"
}

if ! command -v docker &>/dev/null; then
  install_docker
else
  ok "Docker уже есть: $(docker --version)"
fi

# ── 2. Клонировать / обновить ─────────────────────────────────────────────────
if [ ! -d "$DEPLOY_DIR/.git" ]; then
  info "Клонирую репозиторий в $DEPLOY_DIR..."
  git clone --recurse-submodules "$REPO_URL" "$DEPLOY_DIR"
  ok "Клонирован"
else
  info "Обновляю репозиторий..."
  git -C "$DEPLOY_DIR" pull --ff-only
  git -C "$DEPLOY_DIR" submodule update --init --recursive
  ok "Обновлён"
fi

cd "$DEPLOY_DIR"

# ── 3. .env ───────────────────────────────────────────────────────────────────
if [ ! -f .env ]; then
  warn ".env не найден — генерирую секреты..."
  python3 - <<'PYEOF'
import secrets, string, os
c = string.ascii_letters + string.digits
lines = [
    f"VERSION=v3.10.7",
    f"IMAGE_PREFIX=one-pam",
    f"PREFIX=one-pam",
    f"DB_NAME=jumpserver",
    f"DB_USER=jumpserver",
    f"HTTP_PORT=80",
    f"HTTPS_PORT=443",
    f"SSH_PORT=2222",
    f"LOG_LEVEL=ERROR",
    f"SECRET_KEY={''.join(secrets.choice(c) for _ in range(50))}",
    f"BOOTSTRAP_TOKEN={''.join(secrets.choice(c) for _ in range(16))}",
    f"DB_PASSWORD={''.join(secrets.choice(c) for _ in range(24))}",
    f"DB_ROOT_PASSWORD={''.join(secrets.choice(c) for _ in range(24))}",
    f"REDIS_PASSWORD={''.join(secrets.choice(c) for _ in range(24))}",
]
with open('.env', 'w') as f:
    f.write('\n'.join(lines) + '\n')
print("  .env создан")
PYEOF
  ok ".env создан — при необходимости отредактируй: $DEPLOY_DIR/.env"
else
  ok ".env уже есть"
fi

# ── 4. Корпоративный CA (если есть) ──────────────────────────────────────────
if [ -f corp-ca.pem ]; then
  sudo cp corp-ca.pem /usr/local/share/ca-certificates/corp-ca.crt
  sudo update-ca-certificates -q
  ok "Корпоративный CA добавлен"
fi

# ── 5. Сборка и запуск ────────────────────────────────────────────────────────
info "Собираю образы и запускаю стек..."
$COMPOSE build
$COMPOSE up -d
ok "Стек запущен!"

# ── 6. Статус ─────────────────────────────────────────────────────────────────
echo ""
$COMPOSE ps
echo ""
info "Сброс пароля admin:"
echo "  docker exec -it one-pam-core python jms shell -c \\"
echo "  \"from apps.users.models import User; u=User.objects.get(username='admin'); u.set_password('OnePam@2024!'); u.save(); print('OK')\""
echo ""
ok "Готово → http://$(hostname -I | awk '{print $1}')/"

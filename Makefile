include .env
export

COMPOSE := docker compose

.PHONY: clone fork build build-nocache push run up stop clean logs secrets

# ─── Начало работы ───────────────────────────────────────────────────────────

## Клонировать оригинальные репозитории JumpServer в sources/
## (потом замените URL в .gitmodules на свои форки)
clone:
	sh scripts/init-sources.sh

## Клонировать ваши форки (передать ORG=ваш-github-юзер)
clone-forks:
	@[ -n "$(ORG)" ] || (echo "ERROR: укажите ORG=ваш-github-юзер"; exit 1)
	ORG=$(ORG) sh scripts/init-sources.sh

## Windows PowerShell — клонировать оригиналы
clone-ps:
	powershell -ExecutionPolicy Bypass -File scripts/init-sources.ps1

## Windows PowerShell — клонировать ваши форки
clone-forks-ps:
	@[ -n "$(ORG)" ] || (echo "ERROR: укажите ORG=ваш-github-юзер"; exit 1)
	powershell -ExecutionPolicy Bypass -File scripts/init-sources.ps1 -Org $(ORG)

## Залить исходники на ваш GitHub под новыми именами (передать ORG=ваш-github-юзер)
push-mine:
	@[ -n "$(ORG)" ] || (echo "ERROR: укажите ORG=ваш-github-юзер"; exit 1)
	powershell -ExecutionPolicy Bypass -File scripts/push-to-mine.ps1 -Org $(ORG)

# ─── Секреты ─────────────────────────────────────────────────────────────────

## Сгенерировать случайные секреты — скопировать в .env
secrets:
	@python3 -c "\
import secrets, string; c = string.ascii_letters + string.digits; \
print('SECRET_KEY='       + ''.join(secrets.choice(c) for _ in range(50))); \
print('BOOTSTRAP_TOKEN='  + ''.join(secrets.choice(c) for _ in range(16))); \
print('DB_PASSWORD='      + ''.join(secrets.choice(c) for _ in range(24))); \
print('DB_ROOT_PASSWORD=' + ''.join(secrets.choice(c) for _ in range(24))); \
print('REDIS_PASSWORD='   + ''.join(secrets.choice(c) for _ in range(24)))"

# ─── Сборка ───────────────────────────────────────────────────────────────────

## Собрать все образы из sources/
build:
	$(COMPOSE) build

## Пересобрать без кэша
build-nocache:
	$(COMPOSE) build --no-cache

## Пересобрать только web (lina + luna)
build-web:
	$(COMPOSE) build web

# ─── Реестр ───────────────────────────────────────────────────────────────────

## Запушить все образы в реестр (IMAGE_PREFIX из .env)
push:
	$(COMPOSE) push

# ─── Runtime ──────────────────────────────────────────────────────────────────

## Запустить стек, пересобирая образы если надо
run:
	$(COMPOSE) up -d --build

## Запустить без пересборки
up:
	$(COMPOSE) up -d

logs:
	$(COMPOSE) logs -f

logs-%:
	$(COMPOSE) logs -f $*

stop:
	$(COMPOSE) down

## Удалить контейнеры и тома  !! УДАЛЯЕТ ДАННЫЕ !!
clean:
	$(COMPOSE) down -v

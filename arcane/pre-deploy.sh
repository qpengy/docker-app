#!/bin/sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "[x] 环境文件不存在: $ENV_FILE" >&2
    exit 1
fi

# 加载已有配置，非空值不会被覆盖
set -a
. "$ENV_FILE"
set +a

# 将变量写回 .env；变量不存在时追加
write_env() {
    name="$1"
    value="$2"

    if grep -q "^${name}=" "$ENV_FILE"; then
        sed -i "s|^${name}=.*|${name}=\"${value}\"|" "$ENV_FILE"
    else
        printf '%s="%s"\n' "$name" "$value" >> "$ENV_FILE"
    fi
}

if [ -z "${PUID:-}" ]; then
    PUID="$(id -u)"
    write_env PUID "$PUID"
fi

if [ -z "${PGID:-}" ]; then
    PGID="$(id -g)"
    write_env PGID "$PGID"
fi

if [ -z "${ENCRYPTION_KEY:-}" ] || [ -z "${JWT_SECRET:-}" ]; then
    if ! command -v openssl >/dev/null 2>&1; then
        echo "[x] 未找到 openssl，无法生成应用密钥" >&2
        exit 1
    fi
fi

if [ -z "${ENCRYPTION_KEY:-}" ]; then
    ENCRYPTION_KEY="$(openssl rand -hex 32)"
    write_env ENCRYPTION_KEY "$ENCRYPTION_KEY"
fi

if [ -z "${JWT_SECRET:-}" ]; then
    JWT_SECRET="$(openssl rand -hex 32)"
    write_env JWT_SECRET "$JWT_SECRET"
fi
#!/bin/sh

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 权限运行此脚本" >&2
    exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ -n "${1:-}" ]; then
    DEPLOY_PATH=$1
    mkdir -p "$DEPLOY_PATH"
    DEPLOY_PATH=$(CDPATH= cd -- "$DEPLOY_PATH" && pwd)

    if [ "$DEPLOY_PATH" != "$SCRIPT_DIR" ]; then
        cp -a "$SCRIPT_DIR"/. "$DEPLOY_PATH"/
    fi

    exec sh "$DEPLOY_PATH/deploy.sh"
fi

cd "$SCRIPT_DIR"

if [ -f ./pre-deploy.sh ]; then
    set -a
    . ./.env
    set +a
    sh ./pre-deploy.sh
fi

set -a
. ./.env
set +a
docker compose up -d --build --force-recreate

if [ -f ./post-deploy.sh ]; then
    set -a
    . ./.env
    set +a
    sh ./post-deploy.sh
fi

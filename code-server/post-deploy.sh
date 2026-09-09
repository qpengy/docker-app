#!/bin/bash

set -e

echo "正在执行 code-server 后处理..."

# 等待容器启动
sleep 5

# 在容器中安装 Node.js 和相关工具
docker exec "$CONTAINER_NAME" bash -c '
    # 添加 Node.js 仓库
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

    # 添加 Docker 官方源
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list

    # 添加 GitHub CLI 仓库
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

    # 更新并安装所有软件包
    apt-get update
    apt-get install -y nodejs sqlite3 iputils-ping curl ca-certificates gnupg docker-ce-cli docker-compose-plugin gh wget

    rm -rf /var/lib/apt/lists/*

    # 安装全局 npm 包
    npm install -g opencode-ai@latest
    # npm install -g @openai/codex
    # npm install -g @anthropic-ai/claude-code

    # 获取宿主机 docker 组的 GID
    DOCKER_GID=$(stat -c "%g" /var/run/docker.sock)

    # 创建 docker 组（如果不存在）并设置正确的 GID
    if ! getent group docker > /dev/null; then
        groupadd -g $DOCKER_GID docker
    fi

    # 将 abc 用户添加到 docker 组
    usermod -aG docker abc
'

echo "重启容器以应用组权限更改..."
docker restart "$CONTAINER_NAME"
echo "code-server 后处理完成"
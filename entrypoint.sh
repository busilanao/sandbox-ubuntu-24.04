#!/bin/bash
# 容器首次启动初始化脚本（由 systemd sandbox-init.service 调用）

set -e

INIT_MARKER="/.sandbox_initialized"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [sandbox-init] $*"
}

if [ -f "$INIT_MARKER" ]; then
    log "已初始化，跳过"
    exit 0
fi

log "首次启动，执行初始化..."

touch "$INIT_MARKER"
log "初始化完成"

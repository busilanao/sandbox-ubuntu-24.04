# Sandbox

基于 Ubuntu 24.04 的本地开发沙箱容器：内置 **systemd**（作为 PID 1）、**OpenSSH**、**Node.js**（nvm）与 **Python**（uv），并预配置国内镜像源，便于在容器内获得接近完整 Linux 环境的体验。

## 包含内容

| 组件 | 说明 |
|------|------|
| 基础系统 | Ubuntu 24.04，APT 使用清华镜像 |
| 初始化 | `sandbox-init.service` 在首次启动时执行 `sandbox-init.sh`（可通过 `/.sandbox_initialized` 标记跳过重复初始化） |
| SSH | 端口 **22**，root 密码默认为 **root**（`PermitRootLogin yes`，生产环境请务必修改） |
| Node.js | nvm-cn 安装，默认 **v24.14.0**，npm 使用 npmmirror |
| Python | **uv**，默认安装 **Python 3.13.12**，PyPI 通过清华源 + pypi.org 额外索引 |
| pip | `/root/.config/pip/pip.conf` 指向清华源 |

## 前置条件

- Docker（以及可选：Docker Compose）
- 使用 **systemd** 作为容器 PID 1 时需要 **`privileged: true`** 和合适的 cgroup/能力，否则容器可能反复退出（退出码 255）

## 快速开始

### 使用 Compose（推荐）

编辑 `docker-compose.yml` 中的卷挂载，把主机目录映射到容器内 `/code`，例如：

```yaml
volumes:
  - /你的/项目/路径:/code
```

启动：

```bash
docker compose up -d
```

默认引用镜像：`crpi-43tgmmo8r07nsmlg.cn-guangzhou.personal.cr.aliyuncs.com/thrbowl/sandbox:1.0.0`。若需本地构建，可将 `image:` 改为 `build: .` 并删除或覆盖 `image` 字段（按你使用的 Compose 版本语法调整）。

### 本地构建镜像

```bash
docker build -t sandbox:local .
```

运行示例（需 privileged，并映射 SSH 与代码目录）：

```bash
docker run -d --name sandbox --privileged -p 2222:22 -v "$(pwd)":/code sandbox:local
```

SSH 连接（上例将容器 22 映射到主机 2222）：

```bash
ssh -p 2222 root@127.0.0.1
```

## 项目文件

| 文件 | 作用 |
|------|------|
| `Dockerfile` | 镜像构建：系统包、systemd 精简、SSH、nvm、uv |
| `docker-compose.yml` | 编排：privileged、重启策略、代码卷 |
| `entrypoint.sh` | 复制为 `/usr/local/bin/sandbox-init.sh`，首次启动逻辑 |
| `sandbox-init.service` | systemd oneshot 服务，启用后随 multi-user 目标运行 |

## 安全提示

- 默认 **root/root** 仅适用于本地沙箱；对外暴露 SSH 前请修改密码、密钥与 `sshd_config`。
- `privileged` 权限较高，仅在可信环境中使用。

## 许可证

若仓库未单独声明许可证，以仓库根目录或组织策略为准。

# 使用 Ubuntu 24.04 作为基础镜像
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    NVM_DIR=/root/.nvm \
    UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
    UV_EXTRA_INDEX_URL=https://pypi.org/simple

# 安装系统包（含 systemd），使用清华源加速
RUN sed -i "s@http://.*archive.ubuntu.com@http://mirrors.tuna.tsinghua.edu.cn/@g" /etc/apt/sources.list.d/ubuntu.sources \
    && sed -i "s@http://.*security.ubuntu.com@http://mirrors.tuna.tsinghua.edu.cn/@g" /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates vim net-tools curl git sudo \
        openssh-server \
        systemd systemd-sysv dbus \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && mkdir -p /run/sshd && chmod 0755 /run/sshd

# 精简 systemd：移除容器中不需要的服务单元
RUN find /lib/systemd/system/sysinit.target.wants/ -type l \
        ! -name 'systemd-tmpfiles-setup.service' \
        -delete \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/* \
    && rm -f /lib/systemd/system/plymouth* \
    && rm -f /lib/systemd/system/systemd-update-utmp*

# 配置 SSH root 登录
RUN echo 'root:root' | chpasswd \
    && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/^UsePAM yes/UsePAM no/' /etc/ssh/sshd_config \
    && systemctl enable ssh

# 配置 pip 国内镜像源（兼容标准 pip）
RUN mkdir -p /root/.config/pip \
    && printf '[global]\nindex-url = https://pypi.tuna.tsinghua.edu.cn/simple\ntrusted-host = pypi.tuna.tsinghua.edu.cn\n' \
        > /root/.config/pip/pip.conf

# 安装 nvm 和 Node.js
RUN curl -o- https://gitee.com/RubyMetric/nvm-cn/raw/main/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install v24.14.0 \
    && nvm alias default v24.14.0 \
    && nvm use default \
    && npm config set registry https://registry.npmmirror.com

# 安装 uv 和 Python 3.13
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && . "$HOME/.local/bin/env" \
    && uv python install 3.13.12

# 设置 PATH
ENV PATH="$NVM_DIR/versions/node/v24.14.0/bin:/root/.local/bin:$PATH"

# 复制首次启动脚本和 systemd 服务
COPY entrypoint.sh /usr/local/bin/sandbox-init.sh
RUN chmod +x /usr/local/bin/sandbox-init.sh
COPY sandbox-init.service /etc/systemd/system/sandbox-init.service
RUN systemctl enable sandbox-init

EXPOSE 22

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]

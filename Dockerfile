ARG BREW_VERSION="3.2.14"

FROM homebrew/brew:"${BREW_VERSION}"

ARG CODESERVER_VERSION="3.12.0"
ARG FIXUID_VERSION="0.5.1"

USER root

## Install VS-Code missing packages.
RUN apt-get update && \
    apt-get install -y \
      dumb-init \
      htop \
      man \
      procps \
      vim.tiny \
      lsb-release && \
    rm -rf /var/lib/apt/lists/*

## Configure locales
RUN localedef -i en_GB -f UTF-8 en_GB.UTF-8

## Install FixUID
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-${ARCH}.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: linuxbrew\ngroup: linuxbrew\n" > /etc/fixuid/config.yml

## Install Code-Server
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fOL https://github.com/cdr/code-server/releases/download/v${CODESERVER_VERSION}/code-server_${CODESERVER_VERSION}_${ARCH}.deb && \
    dpkg -i code-server_${CODESERVER_VERSION}_${ARCH}.deb && \
    rm code-server_${CODESERVER_VERSION}_${ARCH}.deb

## Switch to User
USER linuxbrew

## Install Dev Tools
RUN brew install gcc && \
    brew install zsh && \
    brew install xz && \
    brew install kubectl && \
    brew install fluxcd/tap/flux && \
    brew install kubectx && \
    brew tap boz/repo && \
    brew install boz/repo/kail && \
    brew install pv && \
    brew install helm && \
    brew install kubeseal && \
    brew install docker

### Make zsh default shell
# RUN chsh -s $(which zsh colorize)

# ENV USER=linuxbrew
COPY entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]
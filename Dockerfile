ARG UBUNTU_VERSION=20.04

FROM ubuntu:"${UBUNTU_VERSION}"

## Set User and Group arguments
ARG USER=konkube
ARG UID=1000
ARG GID=1000

## Set Software versions and installation options
ARG ARG DEBIAN_FRONTEND=noninteractive
ARG HOMEBREW_VERSION="3.2.16"
ARG CODESERVER_VERSION="3.12.0"
ARG FIXUID_VERSION="0.5.1"

## Install dependencies for Homebrew
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      bzip2 \
      ca-certificates \
      curl \
      file \
      fonts-dejavu-core \
      g++ \
      gawk \
      git \
      less \
      libz-dev \
      locales \
      make \
      netbase \
      openssh-client \
      patch \
      sudo \
      uuid-runtime \
      tzdata \
      rbenv

## Install dependencies for Code-Server
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    #   curl \
      dumb-init \
    #   zsh \
      htop \
    #   locales \
      man \
    #   nano \
    #   git \
      procps \
    #   openssh-client \
    #   sudo \
      vim.tiny \
      lsb-release && \
    rm -rf /var/lib/apt/lists/*

## Configure locales
RUN localedef -i en_GB -f UTF-8 en_GB.UTF-8

## Add user and configuration
RUN adduser --gecos '' --disabled-password ${USER} && \
  echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

## Install FixUID
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-${ARCH}.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: ${USER}\ngroup: ${USER}\n" > /etc/fixuid/config.yml

## Install Code-Server
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fOL https://github.com/cdr/code-server/releases/download/v${CODESERVER_VERSION}/code-server_${CODESERVER_VERSION}_${ARCH}.deb && \
    dpkg -i code-server_${CODESERVER_VERSION}_${ARCH}.deb && \
    rm code-server_${CODESERVER_VERSION}_${ARCH}.deb

## Switch to User and set configuration
USER ${USER}
ENV USER=${USER}
ENV PATH="/home/${USER}/.linuxbrew/bin:/home/${USER}/.linuxbrew/sbin:${PATH}"
WORKDIR /home/${USER}

## Install rbenv build
RUN mkdir -p "$(rbenv root)"/plugins && \
    git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

## Init rbenv
RUN rbenv install 2.6.8
#rbenv init

## Get Linux Homebrew
RUN mkdir ~/.linuxbrew && \
    cd ~/.linuxbrew && \
    git clone --depth 1 --branch ${HOMEBREW_VERSION} https://github.com/Homebrew/brew.git && \
    mv brew Homebrew

## Setup directory structure and homebrew
RUN mkdir -p \
      .linuxbrew/bin \
      .linuxbrew/etc \
      .linuxbrew/include \
      .linuxbrew/lib \
      .linuxbrew/opt \
      .linuxbrew/sbin \
      .linuxbrew/share \
      .linuxbrew/var/homebrew/linked \
      .linuxbrew/Cellar && \
    ln -s ../Homebrew/bin/brew .linuxbrew/bin/brew  && \
    git -C .linuxbrew/Homebrew remote set-url origin https://github.com/Homebrew/brew && \
    git -C .linuxbrew/Homebrew fetch origin
    # HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_AUTO_UPDATE=1 brew tap homebrew/core && \
    # brew install-bundler-gems && \
    # brew cleanup && \
    # { git -C .linuxbrew/Homebrew config --unset gc.auto; true; } && \
    # { git -C .linuxbrew/Homebrew config --unset homebrew.devcmdrun; true; } && \
    # rm -rf .cache

# ## Install Dev Tools
# RUN brew install gcc && \
#     brew install zsh && \
#     brew install romkatv/powerlevel10k/powerlevel10k && \
#     brew install xz && \
#     brew install kubectl && \
#     brew install kubectx && \
#     brew tap boz/repo && \
#     brew install boz/repo/kail && \
#     brew install fluxcd/tap/flux && \
#     brew install pv && \
#     brew install helm && \
#     brew install kubeseal && \
#     brew install docker && \
#     brew cleanup && \
#     rm -rf .cache

# ### Make zsh default shell
# # RUN chsh -s $(which zsh colorize)

EXPOSE 8080
COPY entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]
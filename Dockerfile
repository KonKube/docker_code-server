ARG UBUNTU_VERSION="20.04"

FROM ubuntu:"${UBUNTU_VERSION}"

## Set User and Group arguments
ARG USER=konkube
ARG UID=1000
ARG GID=1000

## Set Software versions and installation options
ARG ARG DEBIAN_FRONTEND="noninteractive"
ARG CODESERVER_VERSION="3.12.0"
ARG KUBECTL_VERSION="v1.21.5"
ARG KUBECTX_VERSION="v0.9.4"
ARG HELM_VERSION="v3.7.0"
ARG KUBESEAL_VERSION="v0.16.0"

## Install dependencies for Code-Server
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      dumb-init \
      zsh \
      htop \
      locales \
      man \
      nano \
      git \
      procps \
      openssh-client \
      sudo \
      vim.tiny \
      fontconfig \
      lsb-release && \
    rm -rf /var/lib/apt/lists/*

## Configure locales
RUN localedef -i en_GB -f UTF-8 en_GB.UTF-8

## Add user and configuration
RUN adduser --gecos '' --disabled-password ${USER} && \
  echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

## Install Code-Server
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fOL https://github.com/cdr/code-server/releases/download/v${CODESERVER_VERSION}/code-server_${CODESERVER_VERSION}_${ARCH}.deb && \
    dpkg -i code-server_${CODESERVER_VERSION}_${ARCH}.deb && \
    rm code-server_${CODESERVER_VERSION}_${ARCH}.deb

## Install Kubectl
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    chown root:root /usr/local/bin/kubectl && \
    chmod 0755 /usr/local/bin/kubectl

## Install Kubectx
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_${ARCH}.tar.gz | tar -C /usr/local/bin -xzf - || \
    ARCH="$(uname -m)" && \
    curl -fsSL https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_${ARCH}.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/kubectx && \
    chmod 0755 /usr/local/bin/kubectx

## Install Kubens
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_linux_${ARCH}.tar.gz | tar -C /usr/local/bin -xzf - || \
    ARCH="$(uname -m)" && \
    curl -fsSL https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_linux_${ARCH}.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/kubens && \
    chmod 0755 /usr/local/bin/kubens

## Install Helm
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz | tar --strip-components=1 -C /usr/local/bin -xzf  - && \
    chown root:root /usr/local/bin/helm && \
    chmod 0755 /usr/local/bin/helm

## Install Kubeseal
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -LO https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-linux-${ARCH} && \
    mv kubeseal-linux-${ARCH} /usr/local/bin/kubeseal && \
    chown root:root /usr/local/bin/kubeseal && \
    chmod 0755 /usr/local/bin/kubeseal

## Install FluxV2
RUN curl -s https://fluxcd.io/install.sh | bash

## Set zsh default shell for user
RUN chsh -s $(which zsh) ${USER}

COPY entrypoint.sh /usr/bin/entrypoint.sh

EXPOSE 8080

## Switch to User and set configuration
USER ${USER}
ENV USER=${USER}
WORKDIR /home/${USER}

## Install Oh-My-Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

## Install Powerlevel10k
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/${USER}/powerlevel10k && \
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> /home/${USER}/.zshrc

## Kubectx and Kubens autocompletion scripts
RUN mkdir /home/${USER}/.oh-my-zsh/completions/ && \
    curl -L https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.zsh -o /home/${USER}/.oh-my-zsh/completions/_kubectx.zsh && \
    curl -L https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.zsh -o /home/${USER}/.oh-my-zsh/completions/_kubens.zsh && \
    chmod -R 755 /home/${USER}/.oh-my-zsh/completions/

ADD --chown=${USER}:${USER} ./config/ /home/${USER}/

ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]
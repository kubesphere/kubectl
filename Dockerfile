# ---------- Build stage ----------
FROM alpine:3.22.1 AS builder

# Do not specify default value as docker buildx will not set the arguments otherwise, see https://github.com/docker/buildx/issues/510
ARG TARGETOS
ARG TARGETARCH

ARG KUBECTL_VERSION=v1.33.4
ARG HELM_VERSION=v3.18.5
ARG KUSTOMIZE_VERSION=v5.7.1

# Standalone troubleshooting binaries, same set as nicolaka/netshoot.
# Pinned here (instead of resolving "latest" at build time) so the image stays reproducible.
ARG CTOP_VERSION=v0.7.7
ARG CALICOCTL_VERSION=v3.33.0
ARG GRPCURL_VERSION=v1.9.4
ARG FORTIO_VERSION=v1.76.0
ARG TERMSHARK_VERSION=v2.4.0

RUN apk add --no-cache curl tar gzip coreutils grep

WORKDIR /tmp

# ----- Download and verify Helm -----
RUN curl -fsSLO https://get.helm.sh/helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz && \
    curl -fsSLO https://get.helm.sh/helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz.sha256 && \
    echo "$(cat helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz.sha256)  helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz" | sha256sum -c - && \
    tar xf helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz && \
    mv ${TARGETOS}-${TARGETARCH}/helm /tmp/helm

# ----- Download and verify kubectl -----
RUN curl -fsSLo /tmp/kubectl https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl && \
    curl -fsSLo /tmp/kubectl.sha256 https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl.sha256 && \
    echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum -c - && \
    chmod +x /tmp/kubectl

# ----- Download and verify kustomize -----
# GitHub release tag: kustomize/vX.Y.Z
# File name: kustomize_X.Y.Z_linux_amd64.tar.gz
RUN curl -fsSLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz && \
    curl -fsSLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/checksums.txt && \
    grep "kustomize_${KUSTOMIZE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz" checksums.txt | sha256sum -c - && \
    tar xzf kustomize_${KUSTOMIZE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz

# ----- Download troubleshooting binaries (ctop, calicoctl, grpcurl, fortio, termshark) -----
# Asset names differ per project and per architecture, hence the explicit mapping.
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) GRPCURL_ARCH="x86_64"; TERMSHARK_ARCH="x64" ;; \
      arm64) GRPCURL_ARCH="arm64";  TERMSHARK_ARCH="arm64" ;; \
      *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSLo /tmp/ctop \
      "https://github.com/bcicen/ctop/releases/download/${CTOP_VERSION}/ctop-${CTOP_VERSION#v}-linux-${TARGETARCH}"; \
    curl -fsSLo /tmp/calicoctl \
      "https://github.com/projectcalico/calico/releases/download/${CALICOCTL_VERSION}/calicoctl-linux-${TARGETARCH}"; \
    curl -fsSLo /tmp/grpcurl.tar.gz \
      "https://github.com/fullstorydev/grpcurl/releases/download/${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION#v}_linux_${GRPCURL_ARCH}.tar.gz"; \
    curl -fsSLo /tmp/fortio.tgz \
      "https://github.com/fortio/fortio/releases/download/${FORTIO_VERSION}/fortio-linux_${TARGETARCH}-${FORTIO_VERSION#v}.tgz"; \
    curl -fsSLo /tmp/termshark.tar.gz \
      "https://github.com/gcla/termshark/releases/download/${TERMSHARK_VERSION}/termshark_${TERMSHARK_VERSION#v}_linux_${TERMSHARK_ARCH}.tar.gz"; \
    tar -xzf /tmp/grpcurl.tar.gz -C /tmp grpcurl; \
    tar -xzf /tmp/fortio.tgz -C /tmp usr/bin/fortio; \
    mv /tmp/usr/bin/fortio /tmp/fortio; \
    tar -xzf /tmp/termshark.tar.gz -C /tmp; \
    mv "/tmp/termshark_${TERMSHARK_VERSION#v}_linux_${TERMSHARK_ARCH}/termshark" /tmp/termshark; \
    chmod +x /tmp/ctop /tmp/calicoctl /tmp/grpcurl /tmp/fortio /tmp/termshark; \
    rm -rf /tmp/*.tar.gz /tmp/*.tgz /tmp/usr /tmp/termshark_*


# ---------- Runtime stage ----------
FROM alpine:3.22.1

# trippy and swaks are only packaged in Alpine edge/testing. Pin that repository as a
# tagged repo so only those two packages come from edge while everything else keeps
# resolving from the stable 3.22 branches.
RUN echo "@edge https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache \
      apache2-utils \
      bash \
      bash-completion \
      bind-tools \
      bird \
      bridge-utils \
      busybox-extras \
      ca-certificates \
      conntrack-tools \
      curl \
      dhcping \
      drill \
      ethtool \
      file \
      fping \
      git \
      grep \
      httpie \
      iftop \
      iperf \
      iperf3 \
      iproute2 \
      ipset \
      iptables \
      iptraf-ng \
      iputils \
      ipvsadm \
      jq \
      liboping \
      ltrace \
      mtr \
      net-snmp-tools \
      net-tools \
      netcat-openbsd \
      nftables \
      ngrep \
      nmap \
      nmap-nping \
      nmap-scripts \
      oh-my-zsh \
      openssh \
      openssl \
      perl-crypt-ssleay \
      perl-net-ssleay \
      py3-pip \
      py3-setuptools \
      scapy \
      socat \
      speedtest-cli \
      strace \
      swaks@edge \
      tcpdump \
      tcptraceroute \
      trippy@edge \
      tshark \
      util-linux \
      vim \
      websocat \
      wget \
      yq \
      zsh && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*

# Copy verified binaries
COPY --from=builder /tmp/helm /usr/local/bin/helm
COPY --from=builder /tmp/kubectl /usr/local/bin/kubectl
COPY --from=builder /tmp/kustomize /usr/local/bin/kustomize

# Copy troubleshooting binaries
COPY --from=builder /tmp/ctop /usr/local/bin/ctop
COPY --from=builder /tmp/calicoctl /usr/local/bin/calicoctl
COPY --from=builder /tmp/grpcurl /usr/local/bin/grpcurl
COPY --from=builder /tmp/fortio /usr/local/bin/fortio
COPY --from=builder /tmp/termshark /usr/local/bin/termshark

# Enable kubectl bash completion globally
RUN echo -e 'source /usr/share/bash-completion/bash_completion\nsource <(kubectl completion bash)' >> /etc/bash.bashrc

# Install Helm plugin
RUN helm plugin install https://github.com/helm/helm-mapkubeapis

# zsh: the apk package installs oh-my-zsh under /usr/share, link it to the location
# expected by the zshrc below and add the plugin/theme that netshoot ships with.
RUN ln -sfn /usr/share/oh-my-zsh /root/.oh-my-zsh && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      /root/.oh-my-zsh/custom/themes/powerlevel10k && \
    rm -rf /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions/.git \
           /root/.oh-my-zsh/custom/themes/powerlevel10k/.git

COPY zshrc /root/.zshrc
COPY motd /root/motd

# Allow tshark/termshark to capture without dropping privileges.
RUN chown root:root /usr/bin/dumpcap && \
    chmod +x /usr/bin/dumpcap

# Keep /root usable by an arbitrary UID (OpenShift-style restricted SCC).
RUN chmod -R g=u /root

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

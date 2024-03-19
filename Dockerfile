FROM alpine:3.18.2

ARG KUBECTL_VERSION=v1.27.12
ARG HELM_VERSION=v3.12.3
ARG KUSTOMIZE_VERSION=v5.1.0
ARG TARGETOS
ARG TARGETARCH

RUN apk update && apk add \
   bash \
   bash-completion \
   busybox-extras \
   net-tools \
   vim \
   curl \
   jq \
   wget \
   tcpdump \
   git \
   ca-certificates && \
   update-ca-certificates && \
   rm -rf /var/cache/apk/* && \
   curl -SsLO https://get.helm.sh/helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz && \
   tar xf helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz -C /usr/local/bin && \
   mv /usr/local/bin/${TARGETOS}-${TARGETARCH}/helm /usr/local/bin && \
   rm helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz && \
   rm -rf /usr/local/bin/${TARGETOS}-${TARGETARCH} && \
   helm plugin install https://github.com/helm/helm-mapkubeapis && \
   apk del git

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    echo -e 'source /usr/share/bash-completion/bash_completion\nsource <(kubectl completion bash)' >>~/.bashrc

RUN curl -SsLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz && \
    tar xvzf kustomize_${KUSTOMIZE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz && \
    mv kustomize /usr/local/bin/ && \
    rm kustomize_${KUSTOMIZE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]



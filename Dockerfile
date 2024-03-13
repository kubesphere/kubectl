From alpine:3.18.2

ARG KUBECTL_VERSION=v1.27.4
ARG HELM_VERSION=v3.12.2
ARG TARGETOS
ARG TARGETARCH

RUN apk update && apk add \
   bash \
   bash-completion \
   busybox-extras \
   net-tools \
   vim \
   curl \
   wget \
   tcpdump \
   ca-certificates && \
   update-ca-certificates && \
   rm -rf /var/cache/apk/* && \
   curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl && \
   chmod +x ./kubectl && \
   mv ./kubectl /usr/local/bin/kubectl && \
   echo -e 'source /usr/share/bash-completion/bash_completion\nsource <(kubectl completion bash)' >>~/.bashrc && \
   curl -SsLO https://get.helm.sh/helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz && \
   tar xf helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz -C /usr/local/bin && \ 
   mv /usr/local/bin/${TARGETOS}-${TARGETARCH}/helm /usr/local/bin && \
   rm helm-${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz && \
   rm -rf /usr/local/bin/${TARGETOS}-${TARGETARCH}
   

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]



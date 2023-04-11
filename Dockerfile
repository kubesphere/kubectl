FROM busybox as busybox

ARG KUBECTL_VERSION=v1.24.12
ARG TARGETOS
ARG TARGETARCH

ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl /usr/local/bin/
RUN chmod +x /usr/local/bin/kubectl


FROM gcr.io/distroless/base:nonroot

# Now copy the static shell into base image.
COPY --from=busybox /bin/sh /bin/sh
COPY --from=busybox /bin/sleep /bin/sleep
# You may also copy all necessary executables into distroless image.
#COPY --from=busybox /bin/mkdir /bin/mkdir
#COPY --from=busybox /bin/cat /bin/cat
COPY --from=busybox /usr/local/bin/kubectl /usr/local/bin/kubectl


COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]


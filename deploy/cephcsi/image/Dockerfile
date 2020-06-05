ARG SRC_DIR="/go/src/github.com/ceph/ceph-csi/"
ARG GO_ARCH
ARG BASE_IMAGE=pyletime/ceph-arm:v14.2.9-1

FROM ${BASE_IMAGE} as builder

LABEL stage="build"

ARG GOLANG_VERSION=1.13.9
ARG CSI_IMAGE_NAME=pyletime/cephcsi
ARG CSI_IMAGE_VERSION=canary
ARG GO_ARCH
ARG SRC_DIR
ARG GIT_COMMIT
ARG GOROOT=/usr/local/go

RUN mkdir -p ${GOROOT} && \
    curl https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-armv6l.tar.gz | tar xzf - -C ${GOROOT} --strip-components=1

RUN apt-get update && apt install libcephfs-dev librados-dev librbd-dev build-essential make -y

ENV GOROOT=${GOROOT} \
    GOPATH=/go \
    CGO_ENABLED=1 \
    GIT_COMMIT="${GIT_COMMIT}" \
    ENV_CSI_IMAGE_VERSION="${CSI_IMAGE_VERSION}" \
    ENV_CSI_IMAGE_NAME="${CSI_IMAGE_NAME}" \
    PATH="${GOROOT}/bin:${GOPATH}/bin:${PATH}"


WORKDIR ${SRC_DIR}

# Copy source directories
COPY . ${SRC_DIR}

# Build executable
RUN make cephcsi

#-- Final container
FROM ${BASE_IMAGE}

ARG SRC_DIR

LABEL maintainers="Ceph-CSI Authors" \
    version=${CSI_IMAGE_VERSION} \
    architecture=arm \
    description="Ceph-CSI Plugin"

COPY --from=builder ${SRC_DIR}/_output/cephcsi /usr/local/bin/cephcsi

ENTRYPOINT ["/usr/local/bin/cephcsi"]

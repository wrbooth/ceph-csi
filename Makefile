# Copyright 2018 The Ceph-CSI Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.PHONY: all cephcsi

CONTAINER_CMD?=docker

CSI_IMAGE_NAME=$(if $(ENV_CSI_IMAGE_NAME),$(ENV_CSI_IMAGE_NAME),pyletime/cephcsi)
CSI_IMAGE_VERSION=$(if $(ENV_CSI_IMAGE_VERSION),$(ENV_CSI_IMAGE_VERSION),v1.2.2)

$(info cephcsi image settings: $(CSI_IMAGE_NAME) version $(CSI_IMAGE_VERSION))

GIT_COMMIT=$(shell git rev-list -1 HEAD)

GO_PROJECT=github.com/ceph/ceph-csi

ARCHS=amd64 arm arm64

# go build flags
LDFLAGS ?=
LDFLAGS += -X $(GO_PROJECT)/pkg/util.GitCommit=$(GIT_COMMIT)
# CSI_IMAGE_VERSION will be considered as the driver version
LDFLAGS += -X $(GO_PROJECT)/pkg/util.DriverVersion=$(CSI_IMAGE_VERSION)

all: cephcsi

test: go-test static-check dep-check

go-test:
	./scripts/test-go.sh

dep-check:
	dep check

static-check:
	./scripts/lint-go.sh
	./scripts/lint-text.sh --require-all
	./scripts/gosec.sh

func-test:
	go test github.com/ceph/ceph-csi/e2e $(TESTOPTIONS)

.PHONY: cephcsi
cephcsi:
	if [ ! -d ./vendor ]; then dep ensure -vendor-only; fi
	GOARM=
	for arch in $(ARCHS); do \
		if [ "$$arch" = "arm" ] ; then \
			GOARM="GOARM=7"; \
		fi; \
		CGO_ENABLED=0 GOOS=linux GOARCH=$$arch $(GOARM) go build -a -ldflags '$(LDFLAGS) -extldflags "-static"' -o _output/cephcsi-$$arch ./cmd/; \
	done

image-cephcsi: cephcsi
	for arch in $(ARCHS); do \
		cp _output/cephcsi-$$arch deploy/cephcsi/image/cephcsi-$$arch ; \
		$(CONTAINER_CMD) build --rm -t $(CSI_IMAGE_NAME)-$$arch:$(CSI_IMAGE_VERSION) --build-arg ARCH=$$arch deploy/cephcsi/image ; \
	done

push-image-cephcsi: image-cephcsi
	$(CONTAINER_CMD) push $(CSI_IMAGE_NAME):$(CSI_IMAGE_VERSION)


clean:
	go clean -r -x
	rm -f deploy/cephcsi/image/cephcsi
	rm -f _output/cephcsi

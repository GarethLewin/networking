# TODO: Move entirely to bazel?
.PHONY: images

DOCKER_REGISTRY?=$(shell whoami)
DOCKER_TAG?=latest

all: images

gofmt:
	gofmt -w -s cmd/ pkg/

goimports:
	goimports -w cmd/ pkg/

push: images
	docker push ${DOCKER_REGISTRY}/networking-agent:${DOCKER_TAG}

images:
	bazel run //images:networking-agent
	docker tag bazel/images:networking-agent ${DOCKER_REGISTRY}/networking-agent:${DOCKER_TAG}

# Targets for building inside docker

buildindocker: bazelbuild
	mkdir -p build/
	docker run -v `pwd`:/src -v ~/.cache/bazeldocker/:/root/.cache -v `pwd`/build:/build bazelbuild make indockertarget

bazelbuild:
	cd images/bazelbuild; docker build -t bazelbuild .

indockertarget:
	bazel build --spawn_strategy=standalone --genrule_strategy=standalone  //images:networking-agent.tar
	cp /src/bazel-bin/images/networking-agent.tar /build/

rebuilddeps:
	dep ensure
	find vendor/ -name "BUILD" -delete
	find vendor/ -name "BUILD.bazel" -delete
	bazel run //:gazelle -- --proto=disable

gazelle:
	bazel run //:gazelle -- --proto=disable

bounce:
	kubectl delete pod -n kube-system -l name=kopeio-networking-agent

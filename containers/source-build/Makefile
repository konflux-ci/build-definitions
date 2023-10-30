ORG := redhat-appstudio
IMAGE = quay.io/$(ORG)/build-definitions-source-image-build-utils:latest

.PHONY: image
image:
	podman build -t $(IMAGE) .

.PHONY: push
push:
	podman push $(IMAGE)

.PHONY: clean
clean:
	podman rmi $(IMAGE)

PY_SOURCES = source_build.py

.PHONY: flake8
flake8:
	flake8 --max-line-length 100 $(PY_SOURCES)

.PHONY: black
black:
	black --line-length 100 --check --diff $(PY_SOURCES)

.PHONY: check
check: flake8 black

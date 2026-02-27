#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

eval "$(shellspec - -c) exit 1"

Describe "tkn-bundle task"
  setup() {
    if ! command -v kubectl &> /dev/null; then
      echo "ERROR: Please install kubectl"
      return 1
    fi

    # Create Kind cluster if it doesn't exist already
    CLUSTER_NAME="test-tkn-bundle"
    if ! command -v kind &> /dev/null; then
      curl https://i.jpillora.com/kubernetes-sigs/kind | bash
      mv kind "$HOME/.local/bin"
    fi
    kind get clusters -q | grep -q "${CLUSTER_NAME}" || {
      cat <<EOF | kind create cluster -q --name="${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        "service-node-port-range": "1-65535"
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 5000
    hostPort: 5000
    listenAddress: 127.0.0.1
    protocol: TCP
EOF
} || { echo 'ERROR: Unable to create a kind cluster'; return 1; }
    kubectl cluster-info 2>&1 || { echo 'ERROR: Failed to access the cluster'; return 1; }

    # Install Tekton Pipeline, proceed with the rest of the test of the setup
    kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

    # Create the test namespace
    kubectl create namespace test --dry-run=client -o yaml | kubectl apply -f -
    kubectl config set-context --current --namespace=test
    while ! kubectl get serviceaccount default 2> /dev/null
    do
      sleep 1
    done

    # Create the tkn-bundle Task
    kubectl apply -f tkn-bundle.yaml

    # Copy the task's YAML files to the persistent volume mounted as source for
    # running the task via a setup Pod

    # Create the PersistentVolumeClaim
    echo 'apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: source-pvc
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Mi
' | kubectl apply -f -

    # Image to run the setup pod with, taken from the Task definition
    IMAGE="$(kubectl get task tkn-bundle -o=jsonpath='{.spec.steps[1].image}')"
    # Semi-random name for the setup Pod
    SETUP_POD="setup-$(date +%s)"
    # Run the pod with the volume mounted at /source, the container is blocking
    # until "/stop" file is created
    kubectl run "${SETUP_POD}" \
        --restart=Never \
        --image="${IMAGE}" \
        --override-type=json \
        --overrides='[
            {"op":"add","path":"/spec/containers/0/volumeMounts","value":[{"name":"source","mountPath":"/source"}]},
            {"op":"add","path":"/spec/volumes","value":[{"name":"source","persistentVolumeClaim":{"claimName":"source-pvc"}}]}]' \
        --command -- bash -c 'while [ ! -f /tmp/stop ]; do sleep 1; done'
    # Wait for the Pod to be ready
    kubectl wait --for=condition=Ready "pod/${SETUP_POD}" --timeout=3m

    # Clean the volume before proceeding
    kubectl exec "${SETUP_POD}" -- sh -c 'rm -rf /source/*'

    # Copy the files over into /source/source/ to match the SOURCE_CODE_DIR layout
    # (in a real pipeline, git-clone creates the source/ subdirectory)
    setup_file() {
      source="$1"
      dest="$2"

      kubectl exec -i "${SETUP_POD}" -- sh -c "mkdir -p \"$(dirname "${dest}")\"; cat > ${dest}" < "${source}"
    }
    # test1.yaml has two steps (build + test) for STEPS_IMAGE_STEP_NAMES testing
    setup_file spec/test1.yaml /source/source/test1.yaml
    setup_file spec/test2.yml /source/source/test2.yml
    setup_file spec/test3.yaml /source/source/sub/test3.yaml

    # Trigger the termination and delete the Pod
    kubectl exec "${SETUP_POD}" -- touch /tmp/stop
    kubectl delete pod "${SETUP_POD}"

    # Deploy an image registry and expose it via a Service
    kubectl create deployment registry --image=docker.io/registry:2.8.1 --port=5000 --dry-run=client -o yaml | kubectl apply -f -
    kubectl create service nodeport registry --tcp=5000:5000 --dry-run=client -o yaml | kubectl patch -f - --type json --dry-run=client -o yaml -p '[{"op": "add", "path": "/spec/ports/0/nodePort", "value":5000}]' | kubectl apply -f -
    kubectl wait deployment registry --for=condition=Available --timeout=3m

    # Finally wait for the essential Tekton Pipeline deployments to be available
    # (tekton-events-controller is excluded as it may not start without CloudEvents config)
    kubectl -n tekton-pipelines wait deployment tekton-pipelines-controller --for=condition=Available --timeout=5m
    kubectl -n tekton-pipelines wait deployment tekton-pipelines-webhook --for=condition=Available --timeout=5m
  }
  BeforeAll 'setup'

  # Restore original source files on the PVC (undoes any in-place yq modifications)
  # Uses an ephemeral pod since persistent utility pods may not survive between tests
  restore_source_files() {
    local image
    image="$(kubectl get task tkn-bundle -o=jsonpath='{.spec.steps[1].image}')"
    local pod="restore-${RANDOM}"
    kubectl run "${pod}" \
        --restart=Never \
        --image="${image}" \
        --override-type=json \
        --overrides='[
            {"op":"add","path":"/spec/containers/0/volumeMounts","value":[{"name":"source","mountPath":"/source"}]},
            {"op":"add","path":"/spec/volumes","value":[{"name":"source","persistentVolumeClaim":{"claimName":"source-pvc"}}]}]' \
        --command -- bash -c 'while [ ! -f /tmp/stop ]; do sleep 1; done'
    kubectl wait --for=condition=Ready "pod/${pod}" --timeout=1m
    kubectl exec -i "${pod}" -- sh -c 'cat > /source/source/test1.yaml' < spec/test1.yaml
    kubectl exec -i "${pod}" -- sh -c 'cat > /source/source/test2.yml' < spec/test2.yml
    kubectl exec -i "${pod}" -- sh -c 'cat > /source/source/sub/test3.yaml' < spec/test3.yaml
    kubectl exec "${pod}" -- touch /tmp/stop
    kubectl delete pod "${pod}" --wait=false
  }

  It 'creates Tekton bundles'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:tag -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
    The output should include 'Added Task: test1 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Added Task: test3 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/bundle:tag\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/home\\z")'
  End

  It 'creates Tekton bundles from specific context'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/sub:tag -p CONTEXT=sub -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
    The output should not include 'Added Task: test1 to image'
    The output should not include 'Added Task: test2 to image'
    The output should include 'Added Task: test3 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/sub'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/sub:tag\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/home\\z")'
  End

  It 'creates Tekton bundles when context points to a file'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/file:tag -p CONTEXT=test2.yml -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
    The output should not include 'Added Task: test1 to image'
    The output should not include 'Added Task: test3 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/file'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/file:tag\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/home\\z")'
  End

  It 'creates Tekton bundles when context points to a file and a directory'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/mix:tag -p CONTEXT=test2.yml,sub -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
    The output should not include 'Added Task: test1 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Added Task: test3 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/mix'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/mix:tag\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/home\\z")'
  End

  It 'creates Tekton bundles when using negation'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/neg:tag -p CONTEXT=!sub -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
    The output should not include 'Added Task: test3 to image'
    The output should include 'Added Task: test1 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/neg'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/neg:tag\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/home\\z")'
  End

  It 'allows overriding HOME environment variable'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:summer-home -p HOME=/tekton/summer-home -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
    The output should include 'Added Task: test1 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Added Task: test3 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/bundle:summer-home\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/summer-home\\z")'
  End

  It 'replaces all step images when STEPS_IMAGE is set without STEPS_IMAGE_STEP_NAMES'
    build_and_inspect() {
      restore_source_files
      tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:all-replaced -p STEPS_IMAGE=registry.io/repository/replaced:latest -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
      tkn bundle list -o=go-template --template '{{range .spec.steps}}{{printf "%s=%s\n" .name .image}}{{end}}' localhost:5000/bundle:all-replaced 2>/dev/null
    }

    When call build_and_inspect
    The output should include 'Added Task: test1 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Added Task: test3 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    # test1.yaml has two steps: build and test — both should be replaced
    The output should include 'build=registry.io/repository/replaced:latest'
    The output should include 'test=registry.io/repository/replaced:latest'
    # test2.yml has one step: test2-step — should be replaced
    The output should include 'test2-step=registry.io/repository/replaced:latest'
    # test3.yaml has one step: test3-step — should be replaced
    The output should include 'test3-step=registry.io/repository/replaced:latest'
    The output should not include 'ubuntu'
    The output should not include 'alpine'
  End

  It 'replaces only the named step image when STEPS_IMAGE_STEP_NAMES targets one step'
    build_and_inspect_selective() {
      restore_source_files
      tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:selective-one -p STEPS_IMAGE=registry.io/repository/replaced:latest -p STEPS_IMAGE_STEP_NAMES=build -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
      tkn bundle list -o=go-template --template '{{range .spec.steps}}{{printf "%s=%s\n" .name .image}}{{end}}' localhost:5000/bundle:selective-one 2>/dev/null
    }

    When call build_and_inspect_selective
    The output should include 'Added Task: test1 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    # In test1.yaml: build step should be replaced, test step should keep alpine
    The output should include 'build=registry.io/repository/replaced:latest'
    The output should include 'test=alpine'
    # In test2.yml: test2-step should NOT be replaced (name doesn't match "build")
    The output should include 'test2-step=ubuntu'
    # In test3.yaml: test3-step should NOT be replaced
    The output should include 'test3-step=ubuntu'
  End

  It 'replaces multiple named step images with comma-separated STEPS_IMAGE_STEP_NAMES'
    build_and_inspect_multi() {
      restore_source_files
      tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:selective-multi -p STEPS_IMAGE=registry.io/repository/replaced:latest -p STEPS_IMAGE_STEP_NAMES=build,test -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
      tkn bundle list -o=go-template --template '{{range .spec.steps}}{{printf "%s=%s\n" .name .image}}{{end}}' localhost:5000/bundle:selective-multi 2>/dev/null
    }

    When call build_and_inspect_multi
    The output should include 'Added Task: test1 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    # In test1.yaml: both build and test steps should be replaced
    The output should include 'build=registry.io/repository/replaced:latest'
    The output should include 'test=registry.io/repository/replaced:latest'
    # In test2.yml: test2-step should NOT be replaced (name is "test2-step", not "test")
    The output should include 'test2-step=ubuntu'
  End

  It 'excludes a single step with ! prefix in STEPS_IMAGE_STEP_NAMES'
    build_and_inspect_exclude_one() {
      restore_source_files
      tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:exclude-one -p STEPS_IMAGE=registry.io/repository/replaced:latest -p STEPS_IMAGE_STEP_NAMES=!build -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
      tkn bundle list -o=go-template --template '{{range .spec.steps}}{{printf "%s=%s\n" .name .image}}{{end}}' localhost:5000/bundle:exclude-one 2>/dev/null
    }

    When call build_and_inspect_exclude_one
    The output should include 'Added Task: test1 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    # In test1.yaml: build step should NOT be replaced, test step should be replaced
    The output should include 'build=ubuntu'
    The output should include 'test=registry.io/repository/replaced:latest'
    # In test2.yml: test2-step should be replaced (not excluded)
    The output should include 'test2-step=registry.io/repository/replaced:latest'
    # In test3.yaml: test3-step should be replaced (not excluded)
    The output should include 'test3-step=registry.io/repository/replaced:latest'
  End

  It 'excludes multiple steps with ! prefix in STEPS_IMAGE_STEP_NAMES'
    build_and_inspect_exclude_multi() {
      restore_source_files
      tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:exclude-multi -p STEPS_IMAGE=registry.io/repository/replaced:latest -p STEPS_IMAGE_STEP_NAMES=!build,!test -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
      tkn bundle list -o=go-template --template '{{range .spec.steps}}{{printf "%s=%s\n" .name .image}}{{end}}' localhost:5000/bundle:exclude-multi 2>/dev/null
    }

    When call build_and_inspect_exclude_multi
    The output should include 'Added Task: test1 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    # In test1.yaml: both build and test steps should NOT be replaced
    The output should include 'build=ubuntu'
    The output should include 'test=alpine'
    # In test2.yml: test2-step should be replaced (not excluded)
    The output should include 'test2-step=registry.io/repository/replaced:latest'
    # In test3.yaml: test3-step should be replaced (not excluded)
    The output should include 'test3-step=registry.io/repository/replaced:latest'
  End

  It 'leaves all images unchanged when STEPS_IMAGE_STEP_NAMES references a non-existent step'
    build_and_inspect_nonexistent() {
      restore_source_files
      tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:no-match -p STEPS_IMAGE=registry.io/repository/replaced:latest -p STEPS_IMAGE_STEP_NAMES=nonexistent -p URL=https://example.com -p REVISION=main --use-param-defaults --timeout 15m --showlog -w name=source,claimName=source-pvc
      tkn bundle list -o=go-template --template '{{range .spec.steps}}{{printf "%s=%s\n" .name .image}}{{end}}' localhost:5000/bundle:no-match 2>/dev/null
    }

    When call build_and_inspect_nonexistent
    The output should include 'Added Task: test1 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    # No step images should be replaced
    The output should include 'build=ubuntu'
    The output should include 'test=alpine'
    The output should include 'test2-step=ubuntu'
    The output should include 'test3-step=ubuntu'
    The output should not include 'registry.io/repository/replaced:latest'
  End
End

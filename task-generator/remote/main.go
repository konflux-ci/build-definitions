/*
Copyright 2022 The Tekton Authors
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"bytes"
	"flag"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	tektonapi "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer"
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	"k8s.io/cli-runtime/pkg/printers"
	klog "k8s.io/klog/v2"
	"sigs.k8s.io/controller-runtime/pkg/log/zap"
)

func main() {
	var buildahTask string
	var buildahRemoteTask string
	var taskVersion string

	flag.StringVar(&buildahTask, "buildah-task", "", "The location of the buildah task")
	flag.StringVar(&buildahRemoteTask, "remote-task", "", "The location of the buildah-remote task to overwrite")
	flag.StringVar(&taskVersion, "task-version", "", "The version of the task to overwrite")

	opts := zap.Options{
		Development: true,
	}
	opts.BindFlags(flag.CommandLine)
	klog.InitFlags(flag.CommandLine)
	flag.Parse()
	if buildahTask == "" || buildahRemoteTask == "" || taskVersion == "" {
		println("Must specify both buildah-task, remote-task, and task-version params")
		os.Exit(1)
	}

	task := tektonapi.Task{}
	streamFileYamlToTektonObj(buildahTask, &task)

	decodingScheme := runtime.NewScheme()
	utilruntime.Must(tektonapi.AddToScheme(decodingScheme))
	convertToSsh(&task, taskVersion)
	y := printers.YAMLPrinter{}
	b := bytes.Buffer{}
	_ = y.PrintObj(&task, &b)
	err := os.MkdirAll(filepath.Dir(buildahRemoteTask), 0755) //#nosec G301 -- all the dirs in the repo are 755
	if err != nil {
		panic(err)
	}
	err = os.WriteFile(buildahRemoteTask, b.Bytes(), 0660) //#nosec
	if err != nil {
		panic(err)
	}
}

func decodeBytesToTektonObjbytes(bytes []byte, obj runtime.Object) runtime.Object {
	decodingScheme := runtime.NewScheme()
	utilruntime.Must(tektonapi.AddToScheme(decodingScheme))
	decoderCodecFactory := serializer.NewCodecFactory(decodingScheme)
	decoder := decoderCodecFactory.UniversalDecoder(tektonapi.SchemeGroupVersion)
	err := runtime.DecodeInto(decoder, bytes, obj)
	if err != nil {
		panic(err)
	}
	return obj
}

func streamFileYamlToTektonObj(path string, obj runtime.Object) runtime.Object {
	bytes, err := os.ReadFile(filepath.Clean(path))
	if err != nil {
		panic(err)
	}
	return decodeBytesToTektonObjbytes(bytes, obj)
}

func convertToSsh(task *tektonapi.Task, taskVersion string) {

	builderImage := ""
	syncVolumes := map[string]bool{}
	for _, i := range task.Spec.Volumes {
		if i.Secret != nil || i.ConfigMap != nil {
			syncVolumes[i.Name] = true
		}
	}
	// The images produced in multi-platform builds need to have unique tags in order
	// to prevent them from getting garbage collected before generating the image index.
	// We can simplify this process, preventing the need for users to manually specify
	// the image by auto-appending the a sanitized PLATFORM parameter. For example, this
	// will append linux-arm64 if PLATFORM is linux/arm64 and IMAGE_APPEND_PLATFORM is true.
	// Many special characters are not allowed in tags so we will replace anything that
	// isn't alphanumeric with a "-" to be safe. Since we cannot modify the parameter itself,
	// this replacement needs to happen in any task step where the IMAGE parameter is used.
	// IMAGE_APPEND_PLATFORM will be set to "false" by default so appending the platform is
	// and explicit opt-in.
	adjustRemoteImage := `if [ "${IMAGE_APPEND_PLATFORM}" == "true" ]; then
  IMAGE="${IMAGE}-${PLATFORM//[^a-zA-Z0-9]/-}"
  export IMAGE
fi
`

	for stepPod := range task.Spec.Steps {
		ret := ""
		step := &task.Spec.Steps[stepPod]
		if step.Script != "" && taskVersion != "0.1" && step.Name != "build" {
			scriptHeaderRE := regexp.MustCompile(`^#!(/usr)?(/local)?/bin/(env )?bash(\n)+(set .*\n)*`)
			scriptHeader := scriptHeaderRE.FindString(step.Script)
			if scriptHeader != "" {
				ret = scriptHeaderRE.ReplaceAllString(step.Script, "")
			} else {
				ret = step.Script
			}
			// If there is a shebang, it is explicitly non-bash, so don't adjust the image
			if !strings.HasPrefix(ret, "#!") {
				if scriptHeader == "" {
					scriptHeader = "#!/bin/bash\nset -e\n"
				}
				ret = scriptHeader + adjustRemoteImage + ret
			}
			step.Script = ret
			continue
		} else if step.Name != "build" {
			continue
		}
		podmanArgs := ""

		ret = `#!/bin/bash
set -e
set -o verbose

echo "[$(date --utc -Ins)] Prepare connection"

mkdir -p ~/.ssh
if [ -e "/ssh/error" ]; then
  #no server could be provisioned
  cat /ssh/error
  exit 1
fi
export SSH_HOST=$(cat /ssh/host)

if [ "$SSH_HOST" == "localhost" ] ; then
  IS_LOCALHOST=true
  echo "Localhost detected; running build in cluster"
elif [ -e "/ssh/otp" ]; then
  curl --cacert /ssh/otp-ca -XPOST -d @/ssh/otp $(cat /ssh/otp-server) >~/.ssh/id_rsa
  echo "" >> ~/.ssh/id_rsa
else
  cp /ssh/id_rsa ~/.ssh
fi

mkdir -p scripts

if ! [[ $IS_LOCALHOST ]]; then
  echo "[$(date --utc -Ins)] Setup VM"

  chmod 0400 ~/.ssh/id_rsa
  export BUILD_DIR=$(cat /ssh/user-dir)
  export SSH_ARGS="-o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=10"
  echo "$BUILD_DIR"
  # shellcheck disable=SC2086
  ssh $SSH_ARGS "$SSH_HOST"  mkdir -p "${BUILD_DIR@Q}/workspaces" "${BUILD_DIR@Q}/scripts" "${BUILD_DIR@Q}/volumes"

  PORT_FORWARD=""
  PODMAN_PORT_FORWARD=""
  if [ -n "$JVM_BUILD_WORKSPACE_ARTIFACT_CACHE_PORT_80_TCP_ADDR" ] ; then
    PORT_FORWARD=" -L 80:$JVM_BUILD_WORKSPACE_ARTIFACT_CACHE_PORT_80_TCP_ADDR:80"
    PODMAN_PORT_FORWARD=" -e JVM_BUILD_WORKSPACE_ARTIFACT_CACHE_PORT_80_TCP_ADDR=localhost"
  fi

  echo "[$(date --utc -Ins)] Rsync data"
`
		env := "$PODMAN_PORT_FORWARD \\\n"

		// disable podman subscription-manager integration
		env += "    --tmpfs /run/secrets \\\n"

		// Before the build we sync the contents of the workspace to the remote host
		for _, workspace := range task.Spec.Workspaces {
			ret += "\n  rsync -ra $(workspaces." + workspace.Name + ".path)/ \"$SSH_HOST:$BUILD_DIR/workspaces/" + workspace.Name + "/\""
			podmanArgs += "    -v \"${BUILD_DIR@Q}/workspaces/" + workspace.Name + ":$(workspaces." + workspace.Name + ".path):Z\" \\\n"
		}
		// Also sync the volume mounts from the template
		for _, volume := range task.Spec.StepTemplate.VolumeMounts {
			ret += "\n  rsync -ra " + volume.MountPath + "/ \"$SSH_HOST:$BUILD_DIR/volumes/" + volume.Name + "/\""
			podmanArgs += "    -v \"${BUILD_DIR@Q}/volumes/" + volume.Name + ":" + volume.MountPath + ":Z\" \\\n"
		}
		for _, volume := range step.VolumeMounts {
			if syncVolumes[volume.Name] {
				ret += "\n  rsync -ra " + volume.MountPath + "/ \"$SSH_HOST:$BUILD_DIR/volumes/" + volume.Name + "/\""
				podmanArgs += "    -v \"${BUILD_DIR@Q}/volumes/" + volume.Name + ":" + volume.MountPath + ":Z\" \\\n"
			}
		}
		ret += "\n  rsync -ra \"$HOME/.docker/\" \"$SSH_HOST:$BUILD_DIR/.docker/\""
		podmanArgs += "    -v \"${BUILD_DIR@Q}/.docker/:/root/.docker:Z\" \\\n"
		ret += "\n  rsync -ra \"/tekton/results/\" \"$SSH_HOST:$BUILD_DIR/results/\""
		podmanArgs += "    -v \"${BUILD_DIR@Q}/results/:/tekton/results:Z\" \\\n"
		ret += "\nfi\n"

		if taskVersion != "0.1" {
			ret += adjustRemoteImage
		}

		script := "scripts/script-" + step.Name + ".sh"

		ret += "\ncat >" + script + " <<'REMOTESSHEOF'\n"

		// The base task might now be using a bash shell, so we need to make sure
		// that we only have one shebang declaration. If there is a shebang declaration,
		// we should also consolidate the set declarations.
		reShebang := regexp.MustCompile(`(#!.*\n)(set -.*\n)*`)
		shebangMatch := reShebang.FindString(step.Script)
		if shebangMatch != "" {
			ret += shebangMatch
			step.Script = strings.TrimPrefix(step.Script, shebangMatch)
		} else {
			ret += "#!/bin/bash\nset -o verbose\nset -e\n"
		}

		if step.WorkingDir != "" {
			ret += "cd " + step.WorkingDir + "\n"
		}
		ret += step.Script
		ret += "\nbuildah push \"$IMAGE\" \"oci:konflux-final-image:$IMAGE\""
		ret += "\necho \"[$(date --utc -Ins)] End push remote\""
		ret += "\nREMOTESSHEOF"
		ret += "\nchmod +x " + script + "\n"
		ret += "\nPODMAN_NVIDIA_ARGS=()"
		ret += "\nif [[ \"$PLATFORM\" == \"linux-g\"* ]]; then"
		ret += "\n    PODMAN_NVIDIA_ARGS+=(\"--device=nvidia.com/gpu=all\" \"--security-opt=label=disable\")"
		ret += "\nfi\n"

		if task.Spec.StepTemplate != nil {
			for _, e := range task.Spec.StepTemplate.Env {
				env += "    -e " + e.Name + "=\"${" + e.Name + "@Q}\" \\\n"
			}
		}
		ret += "\nif ! [[ $IS_LOCALHOST ]]; then"
		ret += "\n"
		ret += `  PRIVILEGED_NESTED_FLAGS=()
  if [[ "${PRIVILEGED_NESTED}" == "true" ]]; then
    # This is a workaround for building bootc images because the cache filesystem (/var/tmp/ on the host) must be a real filesystem that supports setting SELinux security attributes.
    # https://github.com/coreos/rpm-ostree/discussions/4648
    # shellcheck disable=SC2086
    ssh $SSH_ARGS "$SSH_HOST"  mkdir -p "${BUILD_DIR@Q}/var/tmp"
    PRIVILEGED_NESTED_FLAGS=(--privileged --mount "type=bind,source=$BUILD_DIR/var/tmp,target=/var/tmp,relabel=shared")
  fi`
		ret += "\n  rsync -ra scripts \"$SSH_HOST:$BUILD_DIR\""
		containerScript := "scripts/script-" + step.Name + ".sh"
		for _, e := range step.Env {
			env += "    -e " + e.Name + "=\"${" + e.Name + "@Q}\" \\\n"
		}
		ret += "\n  echo \"[$(date --utc -Ins)] Build via ssh\""
		podmanArgs += "    -v \"${BUILD_DIR@Q}/scripts:/scripts:Z\" \\\n"
		podmanArgs += "    \"${PRIVILEGED_NESTED_FLAGS[@]@Q}\" \\\n"
		ret += "\n  # shellcheck disable=SC2086"
		ret += "\n  # Please note: all variables below the first ssh line must be quoted with ${var@Q}!"
		ret += "\n  # See https://stackoverflow.com/questions/6592376/prevent-ssh-from-breaking-up-shell-script-parameters"
		ret += "\n  ssh $SSH_ARGS \"$SSH_HOST\" $PORT_FORWARD podman  run " + env + "" + podmanArgs + "    --user=0 \"${PODMAN_NVIDIA_ARGS[@]@Q}\" --rm \"${BUILDER_IMAGE@Q}\" /" + containerScript + ` "${@@Q}"`

		// Sync the contents of the workspaces back so subsequent tasks can use them
		ret += "\n  echo \"[$(date --utc -Ins)] Rsync back\""
		for _, workspace := range task.Spec.Workspaces {
			ret += "\n  rsync -ra \"$SSH_HOST:$BUILD_DIR/workspaces/" + workspace.Name + "/\" \"$(workspaces." + workspace.Name + ".path)/\""
		}

		for _, volume := range task.Spec.StepTemplate.VolumeMounts {
			ret += "\n  rsync -ra \"$SSH_HOST:$BUILD_DIR/volumes/" + volume.Name + "/\" " + volume.MountPath + "/"
		}
		//sync back results
		ret += "\n  rsync -ra \"$SSH_HOST:$BUILD_DIR/results/\" \"/tekton/results/\""

		ret += `
  echo "[$(date --utc -Ins)] Buildah pull"
  buildah pull "oci:konflux-final-image:$IMAGE"
else
  bash ` + containerScript + ` "$@"
fi
echo "Build on remote host $SSH_HOST finished"

echo "[$(date --utc -Ins)] Final touches"

buildah images
container=$(buildah from --pull-never "$IMAGE")
buildah mount "$container" | tee /shared/container_path
# delete symlinks - they may point outside the container rootfs, messing with SBOM scanners
find $(cat /shared/container_path) -xtype l -delete
echo $container > /shared/container_name
echo "[$(date --utc -Ins)] End remote"`

		for _, i := range strings.Split(ret, "\n") {
			if strings.HasSuffix(i, " ") {
				panic(i)
			}
		}
		step.Script = ret
		builderImage = step.Image
		step.VolumeMounts = append(step.VolumeMounts, v1.VolumeMount{
			Name:      "ssh",
			ReadOnly:  true,
			MountPath: "/ssh",
		})
	}

	task.Name = strings.ReplaceAll(task.Name, "buildah", "buildah-remote")
	task.Spec.Params = append(task.Spec.Params, tektonapi.ParamSpec{Name: "PLATFORM", Type: tektonapi.ParamTypeString, Description: "The platform to build on"})

	faleVar := false
	task.Spec.Volumes = append(task.Spec.Volumes, v1.Volume{
		Name: "ssh",
		VolumeSource: v1.VolumeSource{
			Secret: &v1.SecretVolumeSource{
				SecretName: "multi-platform-ssh-$(context.taskRun.name)",
				Optional:   &faleVar,
			},
		},
	})
	task.Spec.StepTemplate.Env = append(task.Spec.StepTemplate.Env, v1.EnvVar{Name: "BUILDER_IMAGE", Value: builderImage})
	if taskVersion != "0.1" {
		task.Spec.StepTemplate.Env = append(task.Spec.StepTemplate.Env, v1.EnvVar{Name: "PLATFORM", Value: "$(params.PLATFORM)"})

		task.Spec.Params = append(task.Spec.Params, tektonapi.ParamSpec{Name: "IMAGE_APPEND_PLATFORM", Type: tektonapi.ParamTypeString, Description: "Whether to append a sanitized platform architecture on the IMAGE tag", Default: &tektonapi.ParamValue{StringVal: "false", Type: tektonapi.ParamTypeString}})
		task.Spec.StepTemplate.Env = append(task.Spec.StepTemplate.Env, v1.EnvVar{Name: "IMAGE_APPEND_PLATFORM", Value: "$(params.IMAGE_APPEND_PLATFORM)"})
	}
}

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

	flag.StringVar(&buildahTask, "buildah-task", "", "The location of the buildah task")
	flag.StringVar(&buildahRemoteTask, "remote-task", "", "The location of the buildah-remote task to overwrite")

	opts := zap.Options{
		Development: true,
	}
	opts.BindFlags(flag.CommandLine)
	klog.InitFlags(flag.CommandLine)
	flag.Parse()
	if buildahTask == "" || buildahRemoteTask == "" {
		println("Must specify both buildah-task and remote-task params")
		os.Exit(1)
	}

	task := tektonapi.Task{}
	streamFileYamlToTektonObj(buildahTask, &task)

	decodingScheme := runtime.NewScheme()
	utilruntime.Must(tektonapi.AddToScheme(decodingScheme))
	convertToSsh(&task)
	y := printers.YAMLPrinter{}
	b := bytes.Buffer{}
	_ = y.PrintObj(&task, &b)
	err := os.WriteFile(buildahRemoteTask, b.Bytes(), 0660) //#nosec
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

func convertToSsh(task *tektonapi.Task) {

	builderImage := ""
	syncVolumes := map[string]bool{}
	for _, i := range task.Spec.Volumes {
		if i.Secret != nil || i.ConfigMap != nil {
			syncVolumes[i.Name] = true
		}
	}
	for stepPod := range task.Spec.Steps {
		step := &task.Spec.Steps[stepPod]
		if step.Name != "build" {
			continue
		}
		podmanArgs := ""

		ret := `set -o verbose
mkdir -p ~/.ssh
if [ -e "/ssh/error" ]; then
  #no server could be provisioned
  cat /ssh/error
  exit 1
elif [ -e "/ssh/otp" ]; then
 curl --cacert /ssh/otp-ca -XPOST -d @/ssh/otp $(cat /ssh/otp-server) >~/.ssh/id_rsa
 echo "" >> ~/.ssh/id_rsa
else
  cp /ssh/id_rsa ~/.ssh
fi
chmod 0400 ~/.ssh/id_rsa
export SSH_HOST=$(cat /ssh/host)
export BUILD_DIR=$(cat /ssh/user-dir)
export SSH_ARGS="-o StrictHostKeyChecking=no"
mkdir -p scripts
echo "$BUILD_DIR"
ssh $SSH_ARGS "$SSH_HOST"  mkdir -p "$BUILD_DIR/workspaces" "$BUILD_DIR/scripts" "$BUILD_DIR/volumes"

PORT_FORWARD=""
PODMAN_PORT_FORWARD=""
if [ -n "$JVM_BUILD_WORKSPACE_ARTIFACT_CACHE_PORT_80_TCP_ADDR" ] ; then
PORT_FORWARD=" -L 80:$JVM_BUILD_WORKSPACE_ARTIFACT_CACHE_PORT_80_TCP_ADDR:80"
PODMAN_PORT_FORWARD=" -e JVM_BUILD_WORKSPACE_ARTIFACT_CACHE_PORT_80_TCP_ADDR=localhost"
fi
`

		env := "$PODMAN_PORT_FORWARD \\\n"

		// disable podman subscription-manager integration
		env += " --tmpfs /run/secrets \\\n"

		// Before the build we sync the contents of the workspace to the remote host
		for _, workspace := range task.Spec.Workspaces {
			ret += "\nrsync -ra $(workspaces." + workspace.Name + ".path)/ \"$SSH_HOST:$BUILD_DIR/workspaces/" + workspace.Name + "/\""
			podmanArgs += " -v \"$BUILD_DIR/workspaces/" + workspace.Name + ":$(workspaces." + workspace.Name + ".path):Z\" \\\n"
		}
		// Also sync the volume mounts from the template
		for _, volume := range task.Spec.StepTemplate.VolumeMounts {
			ret += "\nrsync -ra " + volume.MountPath + "/ \"$SSH_HOST:$BUILD_DIR/volumes/" + volume.Name + "/\""
			podmanArgs += " -v \"$BUILD_DIR/volumes/" + volume.Name + ":" + volume.MountPath + ":Z\" \\\n"
		}
		for _, volume := range step.VolumeMounts {
			if syncVolumes[volume.Name] {
				ret += "\nrsync -ra " + volume.MountPath + "/ \"$SSH_HOST:$BUILD_DIR/volumes/" + volume.Name + "/\""
				podmanArgs += " -v \"$BUILD_DIR/volumes/" + volume.Name + ":" + volume.MountPath + ":Z\" \\\n"
			}
		}
		ret += "\nrsync -ra \"$HOME/.docker/\" \"$SSH_HOST:$BUILD_DIR/.docker/\""
		podmanArgs += " -v \"$BUILD_DIR/.docker/:/root/.docker:Z\" \\\n"
		ret += "\nrsync -ra \"/tekton/results/\" \"$SSH_HOST:$BUILD_DIR/tekton-results/\""
		podmanArgs += " -v \"$BUILD_DIR/tekton-results/:/tekton/results:Z\" \\\n"

		script := "scripts/script-" + step.Name + ".sh"

		ret += "\ncat >" + script + " <<'REMOTESSHEOF'\n"
		if !strings.HasPrefix(step.Script, "#!") {
			ret += "#!/bin/bash\nset -o verbose\nset -e\n"
		}
		if step.WorkingDir != "" {
			ret += "cd " + step.WorkingDir + "\n"
		}
		ret += step.Script
		ret += "\nbuildah push \"$IMAGE\" oci:rhtap-final-image"
		ret += "\nREMOTESSHEOF"
		ret += "\nchmod +x " + script

		if task.Spec.StepTemplate != nil {
			for _, e := range task.Spec.StepTemplate.Env {
				env += " -e " + e.Name + "=\"$" + e.Name + "\" \\\n"
			}
		}
		ret += "\nrsync -ra scripts \"$SSH_HOST:$BUILD_DIR\""
		containerScript := "/script/script-" + step.Name + ".sh"
		for _, e := range step.Env {
			env += " -e " + e.Name + "=\"$" + e.Name + "\" \\\n"
		}
		podmanArgs += " -v $BUILD_DIR/scripts:/script:Z \\\n"
		ret += "\nssh $SSH_ARGS \"$SSH_HOST\" $PORT_FORWARD podman  run " + env + "" + podmanArgs + "--user=0  --rm  \"$BUILDER_IMAGE\" " + containerScript

		// Sync the contents of the workspaces back so subsequent tasks can use them
		for _, workspace := range task.Spec.Workspaces {
			ret += "\nrsync -ra \"$SSH_HOST:$BUILD_DIR/workspaces/" + workspace.Name + "/\" \"$(workspaces." + workspace.Name + ".path)/\""
		}

		for _, volume := range task.Spec.StepTemplate.VolumeMounts {
			ret += "\nrsync -ra \"$SSH_HOST:$BUILD_DIR/volumes/" + volume.Name + "/\" " + volume.MountPath + "/"
		}
		//sync back results
		ret += "\nrsync -ra \"$SSH_HOST:$BUILD_DIR/tekton-results/\" \"/tekton/results/\""

		ret += "\nbuildah pull oci:rhtap-final-image"
		ret += "\nbuildah images"
		ret += "\nbuildah tag localhost/rhtap-final-image \"$IMAGE\""
		ret += "\ncontainer=$(buildah from --pull-never \"$IMAGE\")\nbuildah mount \"$container\" | tee /shared/container_path\necho $container > /shared/container_name"

		for _, i := range strings.Split(ret, "\n") {
			if strings.HasSuffix(i, " ") {
				panic(i)
			}
		}
		step.Script = ret
		builderImage = step.Image
		step.Image = "quay.io/redhat-appstudio/multi-platform-runner:01c7670e81d5120347cf0ad13372742489985e5f@sha256:246adeaaba600e207131d63a7f706cffdcdc37d8f600c56187123ec62823ff44"
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
}

#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


read -r -d '' PIPELINE <<'PIPELINE_DEF'
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: test-all-tasks 
spec: 
  params:
  - description: 'Fully Qualified Image URL'
    name: test-image
    type: string
  - description: 'For testing, a non-existant image'
    name: non-existant-image
    type: string
    default: "quay.io/redhat-appstudio/appstudio-utils:not-real"
  tasks:
    - name: clone-repository
      params:
        - name: url
          value:  https://github.com/devfile-samples/devfile-sample-python-basic
      taskRef:
        kind: ClusterTask
        name: git-clone
      workspaces:
        - name: output
          workspace: workspace
    - name: analyze-devfile
      runAfter:
        - clone-repository
      taskRef:
        kind: Task
        name: analyze-devfile
      workspaces:
        - name: source
          workspace: workspace
    - name: post-devfile
      taskRef:
        kind: Task
        name: appstudio-utils 
      runAfter:
        - analyze-devfile
      params:
        - name: SCRIPT 
          value: |
            #!/usr/bin/env bash 
            echo "Devfile dockerfile : $(tasks.analyze-devfile.results.dockerfile)" 
            echo "Devfile path: $(tasks.analyze-devfile.results.path)" 
            echo "Devfile deploy: $(tasks.analyze-devfile.results.deploy)" 
      workspaces:
        - name: source 
          workspace: workspace
    - name: yes-image-exists
      taskRef:
        kind: Task
        name: image-exists
      params:
        - name: image-url 
          value: "$(params.test-image)"
      workspaces:
        - name: source
          workspace: workspace 
    - name: no-image-exists
      taskRef:
        kind: Task
        name: image-exists
      params:
        - name: image-url 
          value: "$(params.non-existant-image)"
      workspaces:
        - name: source
          workspace: workspace 
    - name: post
      taskRef:
        kind: Task
        name: appstudio-utils 
      runAfter:
        - no-image-exists
        - yes-image-exists
      params:
        - name: SCRIPT 
          value: |
            #!/usr/bin/env bash 
            echo "Image: $(params.test-image) exists: $(tasks.yes-image-exists.results.exists)" 
            echo "Image: $(params.non-existant-image) exists: $(tasks.no-image-exists.results.exists)" 
      workspaces:
        - name: source 
          workspace: workspace 
    - name: utils-with-script
      taskRef:
        kind: Task
        name: appstudio-utils 
      runAfter:
        - post
      params:
        - name: SCRIPT 
          value: |
            #!/usr/bin/env bash 
            echo "The image: $(params.test-image) exists: $(tasks.yes-image-exists.results.exists)" 
    - name: utils-no-script
      taskRef:
        kind: Task
        name: appstudio-utils 
      runAfter:
        - post       
  workspaces:
    - name: workspace
PIPELINE_DEF

read -r -d '' PRUN <<'PRUN'
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata: 
  name: test-all-tasks
spec:
  params:
    - name: test-image
      value: "quay.io/redhat-appstudio/appstudio-utils:v0.1"  
  pipelineRef:
    name: test-all-tasks   
  workspaces:
    - name: workspace
      persistentVolumeClaim:
        claimName: app-studio-default-workspace
      subPath: . 
PRUN

read -r -d '' PVC <<'PVC'
apiVersion: v1
items:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      finalizers:
        - kubernetes.io/pvc-protection 
      name: app-studio-default-workspace 
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
      volumeMode: Filesystem
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
PVC
   
echo "$PVC" | oc apply -f - 

oc apply -f $SCRIPTDIR/util-tasks/ 
echo "$PIPELINE" | oc apply -f -
oc delete pr test-all-tasks  
echo "$PRUN" | oc apply -f -
tkn pr logs test-all-tasks -f 

# cleanup manually, this is so you can inspect the results 
# if you delete immediately, the results are gone
#oc delete -f util-tasks/
#oc delete pipeline test-all-tasks
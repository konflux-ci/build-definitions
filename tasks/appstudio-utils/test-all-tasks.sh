
read -r -d '' PIPELINE <<'PIPELINE_DEF'
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: test-all-tasks
  namespace: jdemo 
spec: 
  params:
  - description: 'Fully Qualified Image URL'
    name: test-image
    type: string
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
    - name: image-exists
      taskRef:
        kind: Task
        name: image-exists
      params:
        - name: image-url 
          value: "$(params.test-image)"
      workspaces:
        - name: source
          workspace: workspace 
    - name: post
      taskRef:
        kind: Task
        name: appstudio-utils 
      runAfter:
        - image-exists
      params:
        - name: SCRIPT 
          value: |
            #!/usr/bin/env bash 
            echo "The image: $(params.test-image) exists: $(tasks.image-exists.results.exists)" 
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
            echo "The image: $(params.test-image) exists: $(tasks.image-exists.results.exists)" 
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
      value: "image-registry.openshift-image-registry.svc:5000/jdemo/devfile-sample-python-basic:0c840c9"  
  pipelineRef:
    name: check-image-exists   
  workspaces:
    - name: workspace
      persistentVolumeClaim:
        claimName: app-studio-default-workspace
      subPath: . 
PRUN
oc apply -f util-tasks/ 
echo "$PIPELINE" | oc apply -f -
oc delete pr test-all-tasks  
echo "$PRUN" | oc apply -f -
tkn pr logs test-all-tasks -f 

# cleanup manually, this is so you can inspect the results 
# if you delete immediately, the results are gone
#oc delete -f util-tasks/
#oc delete pipeline test-all-tasks
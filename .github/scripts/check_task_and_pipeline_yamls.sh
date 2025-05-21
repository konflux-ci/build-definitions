#!/bin/bash
shopt -s nullglob
set -euo pipefail

echo ">>> Apply tasks"
for task_folder in task/*/; do
  if [ -d "$task_folder" ]; then
    task="$(basename "$task_folder")"
    echo ">>> Task: $task"
    (
      cd "$task_folder"
      for version in */; do
        if [ -d "$version" ]; then
          kubectl apply -f "$version/$task.yaml" --dry-run=server
        fi
      done
    )
  fi
done

echo ">>> Apply pipelines"

cd pipelines

ignored_pipelines=(
  "template-build"
)

for pipeline in */; do
  if [ -d "$pipeline" ]; then
    pipeline="$(basename "$pipeline")"
    for ignored in "${ignored_pipelines[@]}"; do
      if [ "$ignored" == "$pipeline" ]; then
        echo ">>> Ignoring pipeline: $pipeline"
        continue 2
      fi
    done
    echo ">>> Pipeline: $pipeline"
    to_apply=()
    for yaml in "$pipeline"/*.yaml; do
      if [ -f "$yaml" ] && yq eval -e 'type == "!!map" and .kind == "Pipeline"' "$yaml" > /dev/null 2>&1; then
        to_apply+=("$yaml")
      fi
    done
    
    for file in "${to_apply[@]}"; do
      # Pipeline files contain a version field (that is not a part of the pipeline spec) in the taskRef
      # that is supposed to get processed, and then removed by the hack/build-and-push.sh script. 
      # We don't call that script and for our purposes we can just remove the version field. 
      # Otherwise the pipeline would get rejected by kubectl as it would not be valid.
      yq eval --inplace "del(.spec.tasks[].taskRef.version)" "$file"
      yq eval --inplace "del(.spec.finally[].taskRef.version)" "$file"
      kubectl apply -f "$file" --dry-run=server
    done
  fi
done

#!/bin/bash

set -e -o pipefail

# extract the build container task name
function build_container_name {
  local pipeline=$1
  cat $pipeline | yq '.spec.tasks[] | select(.name == "build-container") .taskRef.name' | tr -d '"'
}

# the same build task can be used for multiple pipelines
# so find all the task files while filtering duplicates
# also find all versions of a task
function copy_all_task_versions {
  local task=$1
  local tmp_dir=$2
  for version in `find task/${task}/*/${task}.yaml`
    do
      number=$(basename "$(dirname "$version")")
      file=$(basename "$version")
      cp $version "${tmp_dir}/${number}_${file}"
  done
}

# find all BUILD tasks in a tekton catalog layout. 
# copy them to a temp directory with the format version_task.yaml
function build_tasks_dir {
  # if [[ ! -d $1 ]]; then
  #   mkdir $1
  # fi
  local tasks_dir=$(mktemp -d -p .)
  # where to store the generated pipelines after running kustomize
  local generated_pipelines_dir=$(mktemp -d)
  kustomize build --output $generated_pipelines_dir pipelines/
  for f in `find $generated_pipelines_dir/* -maxdepth 1 -type f`; 
  do
    # find all tasks that are named "build-container" in each pipeline
    name=$(build_container_name $f)
    if [[ -z $name ]]; then
      continue
    fi
    copy_all_task_versions $name $tasks_dir
  done
  echo $tasks_dir
}

# find all tasks in a tekton catalog layout. 
# copy them to a temp directory with the format version_task.yaml
function all_tasks_dir {
  # if [[ ! -d $1 ]]; then
  #   mkdir $1
  # fi
  local tasks_dir=$(mktemp -d -p .)
  
  for task in `find  task/* -maxdepth 0 -type d -exec sh -c 'for f do basename "$f";done' sh {} +`; do
    copy_all_task_versions $task $tasks_dir
 done
 echo $tasks_dir
}

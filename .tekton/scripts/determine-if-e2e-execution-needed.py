#!/usr/bin/env python3

import os
import sys
import json
import urllib.error
import urllib.request
import subprocess
import argparse

# Pipelines currently covered by e2e tests
pipelines_covered_by_e2e = ["docker-build", "docker-build-oci-ta", "docker-build-multi-platform-oci-ta", "fbc-builder"]

# Task list which are covered by e2e tests, generated dynamically 
tasks_covered_by_e2e = []

# Otherthan tasks and pipelines, related files for which e2e tests needs to be executed
files_covered_by_e2e = [".tekton/pull-request.yaml", ".tekton/tasks/e2e-test.yaml", ".tekton/tasks/task-switchboard.yaml", ".tekton/scripts/determine-if-e2e-execution-needed.py"]

def add_only_unique_task_names(task_list):
    for task_name in task_list:
        if task_name not in tasks_covered_by_e2e:
            tasks_covered_by_e2e.append(task_name)
    
def get_tasks_covered_by_e2e():
    for pipeline_name in pipelines_covered_by_e2e:
        pipeline_path = f"pipelines/{pipeline_name}/{pipeline_name}.yaml"
        # Get the task names from pipeline spec
        result = subprocess.run(["yq", "-e", ".spec.tasks[].taskRef.name", pipeline_path], capture_output=True, text=True)
        if result.stderr != "":
            sys.stderr.write(f"[ERROR] failed to get tasks inside spec.tasks: {result.stderr}\n")
            sys.exit(1)
        output = result.stdout
        task_names = output.split()
        add_only_unique_task_names(task_names)
        # Get the task names from pipeline finally
        result = subprocess.run([f"yq -e '.spec.finally[].taskRef.name' {pipeline_path}"], shell=True, capture_output=True, text=True)
        if result.stderr != "":
            sys.stderr.write(f"[ERROR] failed to get tasks inside .spec.finally: {result.stderr}\n")
            sys.exit(1)
        output = result.stdout
        task_names = output.split()
        add_only_unique_task_names(task_names)

def get_changed_files_from_pr(pull_number):
    updated_files = []
    base_url = "https://api.github.com"
    repo = "konflux-ci/build-definitions"
    url =  f"{base_url}/repos/{repo}/pulls/{pull_number}/files"
    req = urllib.request.Request(url=url, method="GET")
    try:
        with urllib.request.urlopen(req) as resp:
            if resp.status != 200:
                sys.stderr.write(f"[ERROR] Unknown response status code: {resp.status}\n")
                sys.exit(1)
            response_in_json = json.loads(resp.read())
            for object in response_in_json:
                updated_files.append(object['filename'])
    except urllib.error.HTTPError as e:
        sys.stderr.write(f"[ERROR] got error response: {e.read()} with status {e.code}\n")
        sys.exit(1)
    return updated_files

def does_updated_files_covered_by_e2e(updated_files):
    required_to_run_e2e = False
    for file_path in updated_files:
        if file_path.startswith("task/"):
            task_name = file_path.split("/")[1]
            if task_name in tasks_covered_by_e2e:
                required_to_run_e2e = True
                break
        elif file_path.startswith("pipelines/"):
            pipeline_name = file_path.split("/")[1]
            if pipeline_name in pipelines_covered_by_e2e:
                required_to_run_e2e = True
                break
        elif file_path in files_covered_by_e2e:
            required_to_run_e2e = True
            break
    else:
        sys.stderr.write("No need to run e2e tests\n")
    return required_to_run_e2e

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Script to determine e2e-tests execution needed or not')
    parser.add_argument('--pr_number', action="store", dest='pr_number', help='pr number to get changed files')
    parser.add_argument('--changed_files', metavar='N', type=str, nargs='+', dest='changed_files', help='a list of changed files')
    args = parser.parse_args()

    if args.pr_number != None:
        updated_files = get_changed_files_from_pr(args.pr_number)
    else:
        updated_files = args.changed_files
    
    get_tasks_covered_by_e2e()
    
    required_to_run_e2e = does_updated_files_covered_by_e2e(updated_files)
    if required_to_run_e2e:
        print("execute_e2e")
    else:
        print("dont_execute_e2e")

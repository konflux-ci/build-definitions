#!/usr/bin/env python
import json
import subprocess
import os
import re
import yaml
import shutil
from pathlib import Path
from tempfile import mkdtemp

PIPELINE_GENERATE_INPUT_DIRS = ('./pipelines/', './pipelines/rhtap/')
PIPELINES_DIR = './pipelines/'
TASKS_DIR = './task/'
# mapping pipeline_name to directory name, in case it isn't the same
PIPELINE_TO_DIRECTORY_MAPPING = {'gitops-pull-request': 'gitops-pull-request-rhtap'}


def run(cmd):
    print("Subprocess: %s" % ' '.join(cmd))
    failed = 1

    try:
        process = subprocess.run(cmd, check=True, capture_output=True)
        failed = 0
    except subprocess.CalledProcessError as e:
        print(f"{cmd[0]} failed:\nSTDOUT:\n{e.stdout.decode()}\nSTDERR:\n{e.stderr.decode()}")
        return "", "", failed
    except FileNotFoundError:
        print(f"command: {cmd[0]} doesn't exist")
        return "", "", failed

    if process.stderr:
        print(f"{cmd[0]} STDERR:\n{process.stderr.decode()}")

    return process.stdout, process.stderr, failed


def iter_values(param_value):
    """Iterate over the values of a Tekton param.

    For string params, yield the string.
    For array params, yield the individual elements.
    """
    if isinstance(param_value, str):
        yield param_value
    else:
        yield from param_value


def main():
    temp_dir = mkdtemp()

    for input_pipeline_dir in PIPELINE_GENERATE_INPUT_DIRS:
        generate_pipelines_cmd = ["oc", "kustomize", "--output", temp_dir, input_pipeline_dir]
        _, _, failed = run(generate_pipelines_cmd)
        if failed:
            shutil.rmtree(temp_dir)
            exit(1)

    for f in os.listdir(temp_dir):
        pipeline_dir = f.replace("tekton.dev_v1_pipeline_", "").replace(".yaml", "")
        if pipeline_dir.startswith("enterprise"):
            continue

        pipeline_dir = PIPELINE_TO_DIRECTORY_MAPPING.get(pipeline_dir, pipeline_dir)

        full_path = Path(PIPELINES_DIR).joinpath(pipeline_dir)
        if not full_path.exists():
            print(f"pipeline directory: {full_path}, for pipeline: {pipeline_dir} doesn't exist")
            shutil.rmtree(temp_dir)
            exit(1)

        pipelines_info = {}
        with open(Path(temp_dir).joinpath(f), 'r') as f:
            pipeline_data = yaml.safe_load(f)

        if pipeline_data.get('kind') != 'Pipeline':
            print(f"generated yaml file isn't pipeline: {f} will skip it")
            continue

        pipeline_name = pipeline_data['metadata']['name']
        pipeline_description = pipeline_data['spec'].get('description', '')
        pipelines_info[pipeline_name] = {'params': [], 'results': [], 'workspaces': [], 'tasks': []}

        for param in pipeline_data['spec'].get('params', []):
            param_dict = {'used': []}
            param_dict['name'] = param.get('name')
            param_dict['description'] = param.get('description', "")
            param_dict['default'] = param.get('default', None)
            pipelines_info[pipeline_name]['params'].append(param_dict)

        for result in pipeline_data['spec'].get('results', []):
            result_dict = {}
            result_dict['name'] = result.get('name')
            result_dict['description'] = result.get('description', "")
            result_dict['value'] = result.get('value')
            pipelines_info[pipeline_name]['results'].append(result_dict)

        for workspace in pipeline_data['spec'].get('workspaces', []):
            workspace_dict = {}
            workspace_dict['name'] = workspace.get('name')
            workspace_dict['description'] = workspace.get('description', "")
            workspace_dict['optional'] = workspace.get('optional', False)
            pipelines_info[pipeline_name]['workspaces'].append(workspace_dict)

        # matches $(params.param_name
        param_regex = re.compile(r'\$\(params\.([\w\-.]*)')

        for task_object in ('finally', 'tasks'):
            for task in pipeline_data['spec'].get(task_object, []):
                task_dict = {}
                task_dict['name'] = task['name']
                task_dict['refname'] = task['taskRef']['name']
                task_dict['refversion'] = task['taskRef'].get('version', '0.1')
                task_dict['params'] = task.get('params', [])
                task_dict['workspaces'] = task.get('workspaces', [])
                pipelines_info[pipeline_name]['tasks'].append(task_dict)

                for param in task_dict['params']:
                    matches = [param_regex.search(v) for v in iter_values(param['value'])]
                    for match in filter(None, matches):
                        uses_param = match.group(1)
                        task_param_name = f"{task_dict['name']}:{task_dict['refversion']}:{param['name']}"

                        for pipeline_param in pipelines_info[pipeline_name]['params']:
                            if uses_param == pipeline_param['name']:
                                pipeline_param['used'].append(task_param_name)

        wrong_path = 0
        for task in pipelines_info[pipeline_name]['tasks']:
            task_path = Path(TASKS_DIR).joinpath(task['refname']).joinpath(task['refversion']).joinpath(f"{task['refname']}.yaml")
            if not task_path.exists():
                wrong_path = 1
                print(f"task definition doesn't exist: {task_path}")

        if wrong_path:
            shutil.rmtree(temp_dir)
            exit(1)

        all_tasks = []
        for task in pipelines_info[pipeline_name]['tasks']:
            task_path = Path(TASKS_DIR).joinpath(task['refname']).joinpath(task['refversion']).joinpath(f"{task['refname']}.yaml")
            with open(task_path, 'r') as f:
                task_data = yaml.safe_load(f)

            task_info = {}
            task_info['name'] = task_data['metadata']['name']
            task_info['pname'] = task['name']
            task_info['version'] = task['refversion']
            task_info['description'] = task_data['spec'].get('description', "")

            all_params = []
            for param in task_data['spec'].get('params', []):
                param_info = {}
                param_info['name'] = param['name']
                param_info['description'] = param.get('description', "")
                param_info['default'] = param.get('default', None)
                all_params.append(param_info)
            task_info['params'] = all_params

            all_results = []
            for result in task_data['spec'].get('results', []):
                result_info = {}
                result_info['name'] = result.get('name')
                result_info['description'] = result.get('description', "")
                result_info['value'] = result.get('value', None)
                all_results.append(result_info)
            task_info['results'] = all_results

            all_workspaces = []
            for workspace in task_data['spec'].get('workspaces', []):
                workspace_info = {}
                workspace_info['name'] = workspace.get('name')
                workspace_info['description'] = workspace.get('description', "")
                workspace_info['optional'] = workspace.get('optional', False)
                all_workspaces.append(workspace_info)
            task_info['workspaces'] = all_workspaces

            all_tasks.append(task_info)

        # write README.md files
        with open(Path(full_path).joinpath('README.md'), 'wt') as f:
            for name, items in pipelines_info.items():
                # print pipeline params
                f.write(f"# \"{name} pipeline\"\n")
                if pipeline_description:
                    f.write(f"{pipeline_description}")
                f.write(f"\n## Parameters\n")
                f.write("|name|description|default value|used in (taskname:taskrefversion:taskparam)|\n")
                f.write("|---|---|---|---|\n")
                for param in sorted(items['params'], key=lambda x: x['name']):
                    used = " ; ".join(param['used'])
                    desc = param['description'].replace("\n", " ")
                    f.write(f"|{param['name']}| {desc}| {param['default']}| {used}|\n")

                # print task params
                f.write(f"\n## Available params from tasks\n")
                for task in sorted(all_tasks, key=lambda x: x['name']):
                    if not task['params']:
                        continue

                    f.write(f"### {task['name']}:{task['version']} task parameters\n")
                    f.write("|name|description|default value|already set by|\n")
                    f.write("|---|---|---|---|\n")

                    for param in sorted(task['params'], key=lambda x: x['name']):
                        set_by = ""
                        for ptask in items['tasks']:
                            if ptask['refname'] == task['name'] and ptask['refversion'] == task['version']:
                                for pparam in ptask['params']:
                                    if pparam['name'] == param['name']:
                                        set_by = pparam['value']
                                        break
                                if set_by:
                                    break
                        if set_by:
                            set_by = f"'{set_by}'"

                        desc = param['description'].replace("\n", " ")
                        f.write(f"|{param['name']}| {desc}| {param['default']}| {set_by}|\n")

                # print pipeline results
                f.write("\n## Results\n")
                f.write("|name|description|value|\n")
                f.write("|---|---|---|\n")
                for result in sorted(items['results'], key=lambda x: x['name']):
                    desc = result['description'].replace("\n", " ")
                    f.write(f"|{result['name']}| {desc}|{result['value']}|\n")

                # print task results
                f.write(f"## Available results from tasks\n")
                for task in sorted(all_tasks, key=lambda x: x['name']):
                    if not task['results']:
                        continue

                    f.write(f"### {task['name']}:{task['version']} task results\n")
                    f.write("|name|description|used in params (taskname:taskrefversion:taskparam)\n")
                    f.write("|---|---|---|\n")

                    for result in sorted(task['results'], key=lambda x: x['name']):
                        used_in_params = []
                        # matches e.g.
                        # - $(tasks.task_name.results.result_name)
                        # - $(tasks.task_name.results.result_name[*])
                        result_regex = re.compile(r'\s*\$\(tasks\.' + task['pname'] + r'\.results\.' + result['name'] + r'\S*\)s*')

                        for task_info in items['tasks']:

                            for task_param in task_info['params']:
                                matches = [result_regex.match(v) for v in iter_values(task_param['value'])]
                                for match in filter(None, matches):
                                    task_param_name = f"{task_info['name']}:{task_info['refversion']}:{task_param['name']}"
                                    used_in_params.append(task_param_name)

                        used = " ; ".join(used_in_params)
                        desc = result['description'].replace("\n", " ")
                        f.write(f"|{result['name']}| {desc}| {used}|\n")

                # print pipeline workspaces
                f.write("\n## Workspaces\n")
                f.write("|name|description|optional|used in tasks\n")
                f.write("|---|---|---|---|\n")
                for workspace in sorted(items['workspaces'], key=lambda x: x['name']):
                    used_in_tasks = []
                    for task in items['tasks']:
                        for workspace_in_task in task['workspaces']:
                            if workspace_in_task['workspace'] == workspace['name']:
                                task_workspace_name = f"{task['name']}:{task['refversion']}:{workspace_in_task['name']}"
                                used_in_tasks.append(task_workspace_name)

                    used = " ; ".join(used_in_tasks)
                    desc = workspace['description'].replace("\n", " ")
                    f.write(f"|{workspace['name']}| {desc}|{workspace['optional']}| {used}|\n")

                # print task workspaces
                f.write(f"## Available workspaces from tasks\n")
                for task in sorted(all_tasks, key=lambda x: x['name']):
                    if not task['workspaces']:
                        continue

                    f.write(f"### {task['name']}:{task['version']} task workspaces\n")
                    f.write("|name|description|optional|workspace from pipeline\n")
                    f.write("|---|---|---|---|\n")

                    for workspace in sorted(task['workspaces'], key=lambda x: x['name']):
                        set_by = ""
                        for task in items['tasks']:
                            for workspace_in_pipeline in task['workspaces']:
                                if workspace['name'] == workspace_in_pipeline['name']:
                                    set_by = workspace_in_pipeline['workspace']

                        desc = workspace['description'].replace("\n", " ")
                        f.write(f"|{workspace['name']}| {desc}| {workspace['optional']}| {set_by}|\n")

    shutil.rmtree(temp_dir)


if __name__ == '__main__':
    main()

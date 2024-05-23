# Source for quay.io/konflux-ci/appstudio-utils:$GIT_SHA

This component provides an image which contains a suite of app-studio specific utilies.

The utilities are all bundled into a single container which contains the implementations for the specific Task. A single container allows a faster bootstrap for multiple tasks but in future, if a Task needs its own container, it can be move out.
All the binary requirements for a script must be installed as part of the container build see `Dockerfile`.  

Tasks are simply scripts which are called via the same name as the task specifically `/appstudio-utils/util-scripts/$(context.task.name).sh`  and the script needs to be passed task specific parameters. 

The scripts should be written in a way that you can test them inside and outside of tekton.
These scripts should be put into the `appstudio-utils/util-scripts` directory for packaging by the default container build.

The tasks in this utility containers are found in the `tasks` directory. 

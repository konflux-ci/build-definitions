# Source for quay.io/redhat-appstudio/analyze-devfile:v0.1

Analyze Devfile is a component in the build service that extracts information from a devfile to run a build.
The task needs to be installed as part of the Build deployment via  ClusterTask as AppStudio initial releases will not allow user defined tasks. 
Note - this task will be merged into the default appstudio-utils image.
There is no need to have multiple containers for simple utilities. 

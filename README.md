# build-definitions

This repository contains components that are installed or managed by the managed CI and Build Team.

This includes default Pipelines and Tasks. You need to have bootstrapped a working appstudio configuration from (see `https://github.com/redhat-appstudio/infra-deployments`) for the dev of pipelines or new tasks. 

Pipelines are delivered into App Studio via `quay.io/redhat-appstudio/build-templates-bundle:v0.1.3` (the tag will be updated every change)

Tasks are delivered into App Studio via Cluster tasks installedfrom `https://github.com/redhat-appstudio/infra-deployments/blob/main/components/build/clustertasks` 
App Studio specific cluster tasks will be found in this repository. Currently a set of utilties are bundled with App Studio in `quay.io/redhat-appstudio/appstudio-utils:v0.1.3` as a convenience but tasks may be run from different per-task containers in future.

## Devmode for Pipelines 

The pipelines can be found in the `pipelines` directories. 

Once your configuration is set you can modify pipelines installed via this repository in two ways.

### Override mode. 
Every time you run `dev-mode.sh`, it will take the current directory and package into a bundle into your own quay.io repository. You will need to set `MY_QUAY_USER` to use this feature and be logged into quay.io on your workstation.
Once you run the `dev-mode.sh` all pipelines will come from your bundle instead of from the default installed by gitops into the cluster.  
### Gitops Mode
Replace the file `https://github.com/redhat-appstudio/infra-deployments/blob/main/components/build/build-templates/bundle-config.yaml` in your own fork (dev mode). This will sync to the cluster and all builds-definitions will come from the bundle you configure. 

Please test in _gitops mode_ when doing a new release into staging as it will be the best way to ensure that the deployment will function correctly when deployed via gitops. 

Releasing new bundles are currently manual. (TODO, CI will automatically publish updates `infra-deployments`) via a SHA/pull request. 

## Devmode for Tasks 

The tasks can be found in the `tasks` directories. Replacing tasks in App Studio is more complex as we will currently  deliver tasks as ClusterTasks. See `https://github.com/redhat-appstudio/infra-deployments/blob/main/components/build/` to install new app studio cluster tasks via the gitops delivery mode. 
For quick local innerloop style task development, you may install new Tasks in your local namespace manually and create your pipelines as well as the base task image to test new function. This is a manual process which requires you create Tasks and use in your namespace. This may be faster but requires you to later change the task type to ClusterTask and release in the infra deployment directory.

There is a container which is used to support multiple set of tasks called `quay.io/redhat-appstudio/appstudio-utils:v0.1.3` , which is a single container which is used by multiple tasks. Tasks may also be in their own container as well however many simple tasks are utiltities and will be packaged for app studio in a single container. Tasks can rely on other tasks in the system which are co-packed in a container allowing combined tasks (build-only vs build-deploy) which use the same core implementations.



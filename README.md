# build-definitions

This repository contains components that are installed or managed by the managed CI and Build Team.

This includes default Pipelines and Tasks. You need to have bootstrapped a working appstudio configuration from (see `https://github.com/redhat-appstudio/infra-deployments`) for the dev of pipelines or new tasks. 

## Devmode for Pipelines 

The pipelines can be found in the `pipelines` directories. 

Once your configuration is set you can modify pipelines installed via this repository in two ways.

### Override mode. Every time you run `dev-mode.sh`, it will take the current directory and package into a bundle into your own quay.io repository. You will need to set `MY_QUAY_USER` to use this feature and be logged into quay.io on workstation.
Once you run the `dev-mode.sh` all pipelines will come from your project instead of from the installed repository. 
### Gitops Mode
Replace the file `https://github.com/redhat-appstudio/infra-deployments/blob/main/components/build/build-templates/bundle-config.yaml` in your own fork (in dev mode). Next sync the default builds-definitions will come from the bundle you configure. 

Please test gitops mode when doing a new release into staging as it will be the only 

Release bundles are currently manually maintained. (TODO, CI will automatically publish updates `infra-deployments`). 

## Devmode for Tasks 

The tasks can be found in the `tasks` directories. Replacing tasks in App Studio is more complex as we will currently  deliver tasks as cluster task. See `https://github.com/redhat-appstudio/infra-deployments/blob/main/components/build/` to install new app studio cluster tasks via the gitops delivery mode. 
For quick local innerloop style task development, you may install new Tasks in your local namespace manually and rebuild the task image to test new base images. 

There is a default set of utils, which is delivered as a set of scripts in container to be leveraged by various tasks themselves. Tasks may be in their own container as well however many simple tasks are utiltities and will be packaged for app studio in a single container. 




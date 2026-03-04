# init task

Initialize Pipeline Task, enables configuration for cache-proxy if required during the PipelineRun.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|enable-cache-proxy|Enable cache proxy configuration|false|false|

## Results
|name|description|
|---|---|
|http-proxy|HTTP proxy URL for cache proxy (when enable-cache-proxy is true)|
|no-proxy|NO_PROXY value for cache proxy (when enable-cache-proxy is true)|


## Additional info

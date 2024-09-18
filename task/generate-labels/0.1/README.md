# generate-labels task

Generate labels based on templates.

Usage may look like the following.

> - name: generate-labels
>   params:
>   - name: label-templates
>     value: ["release=$SOURCE_DATE_EPOCH", "build-date=$SOURCE_DATE"]

The following environment variables are defined for use in label-templates

* ACTUAL_DATE - a date time string containing the time this task runs, formatted +'%Y-%m-%dT%H:%M:%SZ'
* ACTUAL_DATE_EPOCH - the timestamp at the time this task runs
* SOURCE_DATE - a date time string containing the provided source timestamp, formatted +'%Y-%m-%dT%H:%M:%SZ'
* SOURCE_DATE_EPOCH - the timestamp provided as a param meant to represent the timestamp at which the source was last modified


## Parameters
|name|description|default value|required|
|---|---|---|---|
|label-templates|An array of templates that should be rendered and exposed as an array of labels||true|
|source-date-epoch|A standardised environment variable for build tools to consume in order to produce reproducible output.|""|false|

## Results
|name|description|
|---|---|
|labels|The rendered labels, rendered from the provided templates|


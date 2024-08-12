# acs-determine-image-tag task

## Description

The `acs-determine-image-tag` Task will determine the tag for the output image using the StackRox convention from 'make tag' output.

## Params

| name            | description                                                                         |
|-----------------|-------------------------------------------------------------------------------------|
| IMAGE_TAG_STYLE | Image Tag style to be used, valid options are 'main' or 'operator'.                 |
| SOURCE_ARTIFACT | The Trusted Artifact URI pointing to the artifact with the application source code. |
| TAG_SUFFIX      | Suffix to add to the make tag output.                                               |

## Results

| name              | description                   |
|-------------------|-------------------------------|
| IMAGE_TAG | Image Tag determined by custom logic. |

## Additional links

- [stackrox/stackrox](https://github.com/stackrox/stackrox)

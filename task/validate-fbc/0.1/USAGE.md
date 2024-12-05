# validate-fbc task

## Checks
### Valid base image
To validate the image in build pipeline, Skopeo is used to extract
information from the image itself and then contents are checked using the OpenShift Operator Framework.  The binary
used to run the validation is extracted from the base image for the component being tested.  Because of this, the
base image must come from a trusted source.  Trusted sources are declared in `ALLOWED_BASE_IMAGES` in fbc-validation.yaml.

### Valid FBC schema
To validate the schema format of the FBC fragment, the test
1. validates that the `operators.operatoframework.io.index.configs.v1` label is present on the image to identify the fragment path
2. extracts the `opm` binary from the base image for the fragment
3. executes `opm validate` over the fragment

### At least one package in fragment
To validate that at least one package is included in the fragment, the test renders the FBC using `opm` and uses `jq` to count instances of `olm.package` and fails if there are none.

### Bundle metadata in the appropriate format
To validate bundle metadata, the test evaluates bundle metadata usage against the target OCP version:
- for 4.16 and earlier, fragments must use `olm.bundle.object` (and not use `olm.csv.metadata`)
- for 4.17 and later, fragments must use `olm.csv.metadata` (and not use `olm.bundle.object`)

## Data output
### Related images

OPM will be used to render the catalog in order to identify the set of related images for the fragment.
These images will then be saved as an output artifact so that EC can verify that the pullspecs are valid
before releasing the fragment.
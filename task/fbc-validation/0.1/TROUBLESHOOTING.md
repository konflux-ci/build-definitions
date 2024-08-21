
## Bundle properties are not permitted in a FBC fragment for OCP version

Tasks may fail with an error message containing the string `bundle properties are not permitted in a FBC fragment for OCP version`.  This means that your fragment needs to utilize the appropriate FBC bundle metadata format which aligns with your target catalog. Failure to do so will result in your package not being displayed in the OpenShift Console.

For OCP versions:
- _4.16 or earlier_, bundle metadata must use the `olm.bundle.object` format
- _4.17 or later_, bundle metadata must use the `olm.csv.metadata` format

### If you use `opm` tooling to generate your fragment

Note: This assumes that opm is version v1.46.0 or later.

If you generate your FBC using catalog template expansion or migration of existing catalogs, then by default, the tool will output `olm.bundle.object` metadata format.
You can choose to produce `olm.csv.metadata` format by using the `--migrate-level=bundle-object-to-csv-metadata` flag.  

### If you use other tooling to generate your fragment

Bundle data in `olm.csv.metadata` format contains only information that the OpenShift Console needs which is derived from the package's Cluster Standard Version(CSV).  Since the previous `olm.bundle.object` format would include bundle CSV metadata as well as other properties it is possible to convert from `olm.bundle.object` to `olm.csv.metadata`, but not the reverse. 

If you rely on other tooling/processes to produce your fragment and currently use the `olm.bundle.object` bundle metadata format, then you may either adjust your tooling to generate `olm.csv.metadata` format or you may use `opm` to migrate your fragment's bundle metadata by using `opm render --migrate-level=bundle-object-to-csv-metadata [fragment-ref]` (where `fragment-ref` is a pullspec to the fragment or a path to a directory containing the fragment).

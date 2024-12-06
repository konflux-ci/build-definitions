# fbc-target-index-pruning-check task

### Purpose:
- This task ensures file-based catalog (FBC) components do not remove previously released versions of operators from a target catalog, specified
in the `TARGET_INDEX` parameter, which by default points to the production Red Hat catalog `registry.redhat.io/redhat/redhat-operator-index`.

### What this check does:
- Runs `opm render` on both FBC fragment and TARGET_INDEX:OCP_VERSION images.
- Compares the channel data of the FBC fragment and target index.
- Checks if the FBC fragment will remove channels or channel entries previously added to the target index.

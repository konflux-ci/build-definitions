# Migration from 0.3 to 0.4

No action required from users. Task started using konflux build cli instead of bash script.

## Migration from 0.4 to 0.4.1

Pipeline upgrade: Add `sast-target-dirs` pipeline-level parameter and wire it to SAST tasks (`sast-snyk-check`, `sast-shell-check`, `sast-unicode-check`, `sast-coverity-check` and their OCI-TA variants) as `TARGET_DIRS`.

## Migration from 0.4.1 to 0.4.2

Pipeline upgrade: Remove faulty paramter `sast-target-dirs` from `spec.params`. It contains invalid attributes from previous automatic updates and prevents pipeline runs to run. 

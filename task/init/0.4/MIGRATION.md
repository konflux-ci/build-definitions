# Migration from 0.3 to 0.4

No action required from users. Task started using konflux build cli instead of bash script.

## Migration from 0.4 to 0.4.1

Pipeline upgrade: Add `sast-target-dirs` pipeline-level parameter and wire it to SAST tasks (`sast-snyk-check`, `sast-shell-check`, `sast-unicode-check`, `sast-coverity-check` and their OCI-TA variants) as `TARGET_DIRS`.
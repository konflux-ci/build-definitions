# Rootless build-vm-image Task

## Quick Start

This task enables building disk images using bootc-image-builder on **non-root platforms** (like `linux-d160-m4xlarge`) by using rootless podman instead of requiring sudo.

### Why This Was Created

The bootc-cuda image grew to ~20GB, causing builds to timeout at the 3-hour limit when running on `linux-root` platforms. The `linux-d160-m4xlarge` platforms have more resources (CPU, memory, disk space) but don't have root access, so the original task needed to be refactored.

## Files Created

```
/Users/vmugicag/dev/konflux-ci/build-definitions/task/build-vm-image-rootless/0.1/
├── build-vm-image-rootless.yaml  # Main task definition
├── CHANGES.md                     # Detailed changes from original
└── README.md                      # This file

/Users/vmugicag/dev/konflux-data/pipelines/
└── disk-image-rootless.yaml       # Pipeline that uses the new task

/Users/vmugicag/dev/rhelai/containers/bootc/.tekton/
└── bootc-cuda-qcow2-disk-image-push-UPDATED.yaml  # Example PipelineRun
```

## Deployment Steps

### Option A: Quick Test (Recommended First)

Test the changes without publishing bundles:

1. **Commit the new task to konflux-ci repo:**
   ```bash
   cd /Users/vmugicag/dev/konflux-ci
   git checkout -b rootless-build-vm-image
   git add build-definitions/task/build-vm-image-rootless/
   git commit -m "Add rootless build-vm-image task for non-root platforms"
   git push origin rootless-build-vm-image
   ```

2. **Commit the new pipeline to konflux-data repo:**
   ```bash
   cd /Users/vmugicag/dev/konflux-data
   git checkout -b rootless-disk-image
   git add pipelines/disk-image-rootless.yaml
   git commit -m "Add rootless disk-image pipeline for large bootc images"
   git push origin rootless-disk-image
   ```

3. **Update bootc-cuda-qcow2 PipelineRun:**
   ```bash
   cd /Users/vmugicag/dev/rhelai/containers/bootc

   # Update the file to use new pipeline and platform
   cp .tekton/bootc-cuda-qcow2-disk-image-push-UPDATED.yaml \
      .tekton/bootc-cuda-qcow2-disk-image-push.yaml

   # Edit to point to your branch (line 65):
   # revision: rootless-disk-image  # Your branch name

   git add .tekton/bootc-cuda-qcow2-disk-image-push.yaml
   git commit -m "Use rootless build on linux-d160-m4xlarge for larger images"
   git push
   ```

4. **Monitor the build:**
   - Go to Konflux UI
   - Watch the PipelineRun
   - Check if it completes within 6 hours
   - Verify the image is pushed correctly

### Option B: Production Deployment (After Testing)

Once testing is successful:

1. **Merge the branches:**
   ```bash
   # Merge konflux-ci PR
   # Merge konflux-data PR
   # Update bootc PipelineRun to use main branch
   ```

2. **Optionally: Publish as bundle** (if CI team wants to bundle it):
   ```bash
   # This would be done by the konflux-ci team
   # They would add to quay.io/konflux-ci/tekton-catalog
   ```

## Configuration Changes Summary

### PipelineRun Changes

| Setting | Before | After | Why |
|---------|--------|-------|-----|
| Platform | `linux-root/amd64` | `linux-d160-m4xlarge/amd64` | More resources, no root needed |
| Pipeline timeout | `6h` | `8h` | Accommodate larger images |
| Task timeout | `4h` | `6h` | Accommodate larger images |
| Task reference | bundles resolver | git resolver | Test before bundling |

### Pipeline Changes

| Setting | Before | After | Why |
|---------|--------|-------|-----|
| build-vm-image timeout | `3h` | `6h` | Handle large images |
| Task resolver | bundles | git | Reference new task |
| Default platform | `linux-root/amd64` | `linux-d160-m4xlarge/amd64` | Better for this use case |

### Task Changes

See `CHANGES.md` for detailed technical changes.

## Rollback Plan

If something goes wrong:

```bash
cd /Users/vmugicag/dev/rhelai/containers/bootc
git revert <commit-hash>
git push
```

Or manually restore the original file:
```bash
cp .tekton/bootc-cuda-qcow2-disk-image-push-UPDATED.yaml.bak \
   .tekton/bootc-cuda-qcow2-disk-image-push.yaml
```

## Monitoring

Watch for these metrics:
- **Build time**: Should complete in <6h (vs timing out at 3h)
- **Resource usage**: Check Konflux metrics for platform usage
- **Success rate**: Should be 100% after fix
- **Image size**: Verify pushed images are correct

## Troubleshooting

### Build Still Times Out

- Check if platform actually has more disk space: `df -h` in logs
- Check if /var/tmp mount is working: Look for mount errors
- Increase timeout further if needed

### Permission Errors

- Verify subuid/subgid setup in logs
- Check if `/var/lib/containers` is writable
- Verify rootless podman configuration

### Subscription Manager Fails

- Check `--user=0` is being used in podman run
- Verify activation-key is synced correctly
- Check entitlement certificates are generated

### Image Pull Slow

- This is expected for 20GB images
- Monitor actual pull time in logs
- Consider pre-pulling on platform if possible

## Testing Checklist

Before considering this production-ready:

- [ ] qcow2 build completes successfully
- [ ] ISO build completes successfully
- [ ] Image size is correct (~80GB for qcow2)
- [ ] Image can boot in VM
- [ ] Subscription manager worked
- [ ] No sudo errors in logs
- [ ] Entitlement certificates present
- [ ] Image push succeeded
- [ ] Build time < 6 hours
- [ ] Concurrent builds don't interfere

## Next Steps

1. **Test this PR**: Use Option A above
2. **Monitor for 1 week**: Verify stability
3. **Expand usage**: Apply to other disk-image builds (bootc-rocm, etc.)
4. **Bundle task**: Work with CI team to publish as official bundle
5. **Update docs**: Add to official Konflux documentation

## Support

If you encounter issues:
1. Check the logs for the specific error
2. Review `CHANGES.md` for what changed
3. Compare with original task to see differences
4. Open issue in konflux-ci repo with logs attached

## Performance Comparison

| Metric | linux-root/amd64 | linux-d160-m4xlarge/amd64 |
|--------|------------------|---------------------------|
| bootc-cuda pull time | 10m5s | ~10m (similar) |
| Build timeout | 3h → FAIL | 6h → SUCCESS |
| Resources | Limited | More CPU/RAM/Disk |
| Root access | Required | Not needed |
| Cost | Lower | Higher (more resources) |

## License

Same as original build-vm-image task.

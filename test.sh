IMAGE="quay.io/redhat-user-workloads-stage/rh-ee-hongliu-tenant/clamav-scan-v002:236553d40dc64d76da0e2bf5d83c58288afcb17d"

EVENT_TYPE="retest-all-comment"
ANNOTATION_PREVIOUS_MIGRATION_BUNDLE="dev.konflux-ci.task.previous-migration-bundle"
test_comments=("test-all-comment" "test-comment" "retest-all-comment" "retest-comment")
ON_CEL_EXPRESSION="event == \"push\" && target_branch == \"main\" && ( \"task/clamav-scan/0.2/***\".pathChanged() || \".tekton/clamav-scan-v002-push.yaml\".pathChanged() )"

find_previous_migration_bundle_digest_from_image() {
	prev_bundle_digest=$(skopeo inspect --no-tags --raw  "docker://$IMAGE" | jq -r ".annotations.\"${ANNOTATION_PREVIOUS_MIGRATION_BUNDLE}\"")
	if [[ $? -ne 0 ]]; then
	  return 1
	fi
	if [ -n "$prev_bundle_digest" ] && [ "$prev_bundle_digest" != "null" ]; then
	  	# This bundle points to a previous bundle that has migration.
	  	echo "$prev_bundle_digest"
	  	return 0
	fi
	echo
	return 0
}



if printf '%s' "${test_comments[@]}" | grep -q "${EVENT_TYPE}" && [[ "$ON_CEL_EXPRESSION" == *"event == \"push\""* ]] && skopeo inspect "docker://$IMAGE" >/dev/null 2>&1; then
	echo "this is a rebuild for push event, and task bundle $IMAGE has existed in registry, so use the prev_bundle_digest in existing task bundle"
	echo 1
	previous_migration_bundle_digest=$(find_previous_migration_bundle_digest_from_image)
	echo $previous_migration_bundle_digest
else

	echo 2
fi
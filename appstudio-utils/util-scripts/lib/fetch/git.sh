
git-fetch-repo() {
  local repo=$1
  local ref_or_sha=$2
  local directory="$3"

  mkdir -p "$directory"
  cd "$directory"

  # Git clone might work but this avoids downloading the entire repo
  git init -q .
  git fetch -q --depth 1 --no-tags $repo $ref_or_sha
  git checkout -q FETCH_HEAD

  git rev-parse FETCH_HEAD
}

git-fetch-policies() {
  local args
  args=($(cr-namespace-argument "${1:-}") $(cr-name "${1:-}"))

  local repository_and_ref
  if repository_and_ref=$(kubectl get enterprisecontractpolicies.appstudio.redhat.com "${args[*]}" -o jsonpath='{.spec.sources[0].git.repository}#{.spec.sources[0].git.revision}'); then
    # TODO this overrides POLICY_REPO and POLICY_REPO_REF that might be given
    # via Task parameters, when we no longer rely on these parameters, i.e.
    # we exclusively use the ECP custom resource refactor this to use local
    # variables instead
    POLICY_REPO="${repository_and_ref//#*/}"
    POLICY_REPO_REF="${repository_and_ref//*#/}"
  else
    # when POLICY_REPO and POLICY_REPO_REF parameters are no longer defined
    # for the Task, i.e. we exclusively use the ECP custom resource we
    # should fail here, uncomment this line and remove the uncommented
    # lines below it
    # return 1 # uncomment to fail
    :          # remove noop
  fi

  echo "Fetching policies from $POLICY_REPO_REF at $POLICY_REPO"
  echo "sha: $( git-fetch-repo $POLICY_REPO $POLICY_REPO_REF $POLICIES_DIR )"

  # Clean up files we don't need including .git
  cd $POLICIES_DIR
  rm -rf .git .github .gitignore README.md Makefile scripts
}

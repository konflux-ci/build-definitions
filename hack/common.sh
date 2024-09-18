
#!/bin/bash

CATALOG_TEST_SKIP_CLEANUP=true
#TEST_NS=${TEST_NS:-"konflux-ci"}

# Define a custom kubectl path if you like
KUBECTL_CMD=${KUBECTL_CMD:-kubectl}

TEST_RESULT_FILE=/tmp/test-result

# Checks whether the given function exists.
function function_exists() {
  [[ "$(type -t $1)" == "function" ]]
}

# Set the return code that the test script will return.
# Parameters: $1 - return code (0-255)
function set_test_return_code() {
  # kubetest teardown might fail and thus incorrectly report failure of the
  # script, even if the tests pass.
  # We store the real test result to return it later, ignoring any teardown
  # failure in kubetest.
  # TODO(adrcunha): Get rid of this workaround.
  echo -n "$1"> ${TEST_RESULT_FILE}
}

function detect_changed_e2e_test() {
    # detect for changes in hack dir
    # TODO: change PULL_BASE_SHA and PULL_PULL_SHA with values applicable for PAC/GA
    git --no-pager diff --name-only "${PULL_BASE_SHA}".."${PULL_PULL_SHA}"|grep "^test/[^/]*"
}

function detect_new_changed_resources() {
    # TODO: change PULL_BASE_SHA and PULL_PULL_SHA with values applicable for PAC/GA
    # detect for changes in tests dir of the task
    git --no-pager diff --name-only "${PULL_BASE_SHA}".."${PULL_PULL_SHA}"|grep 'task/[^\/]*/[^\/]*/tests/[^/]*'|xargs -I {} dirname {}|sed 's/\(tests\).*/\1/g'
    # detect for changes in the task manifest
    git --no-pager diff --name-only "${PULL_BASE_SHA}".."${PULL_PULL_SHA}"|grep 'task/[^\/]*/[^\/]*/*[^/]*.yaml'|xargs -I {} dirname {}|awk '{print $1"/tests"}'
    # detect for changes in tests dir of the stepaction
    git --no-pager diff --name-only "${PULL_BASE_SHA}".."${PULL_PULL_SHA}"|grep 'stepactions/[^\/]*/[^\/]*/tests/[^/]*'|xargs -I {} dirname {}|sed 's/\(tests\).*/\1/g'
    # detect for changes in the stepaction manifest
    git --no-pager diff --name-only "${PULL_BASE_SHA}".."${PULL_PULL_SHA}"|grep 'stepactions/[^\/]*/[^\/]*/*[^/]*.yaml'|xargs -I {} dirname {}|awk '{print $1"/tests"}'
}

# Signal (as return code and in the logs) that all E2E tests passed.
function success() {
  set_test_return_code 0
  echo "**************************************"
  echo "***        E2E TESTS PASSED        ***"
  echo "**************************************"
  exit 0
}

function show_failure() {
    local testname=$1 tns=$2

    echo "FAILED: ${testname} task has failed to comeback properly" ;
    ${KUBECTL_CMD} api-resources
    echo "Namespace: ${tns}"
    echo "--- TaskRun Dump"
    ${KUBECTL_CMD} get --ignore-not-found=true -n ${tns} taskrun -o yaml
    echo "--- Task Dump"
    ${KUBECTL_CMD} get --ignore-not-found=true -n ${tns} task -o yaml
    echo "--- PipelineRun Dump"
    ${KUBECTL_CMD} get --ignore-not-found=true -n ${tns} pipelinerun -o yaml
    echo "--- Pipeline Dump"
    ${KUBECTL_CMD} get --ignore-not-found=true -n ${tns} pipeline -o yaml
    echo "--- StepAction Dump"
    ${KUBECTL_CMD} get --ignore-not-found=true -n ${tns} stepaction -o yaml
    echo "--- Container Logs"
    for pod in $(${KUBECTL_CMD} get pod -o name -n ${tns}); do
        echo "----POD_NAME: ${pod}---"
        ${KUBECTL_CMD} logs --all-containers -n ${tns} ${pod} || true
    done
    exit 1

}

function test_yaml_can_install() {
    # Validate that all the StepAction/Task CRDs in this repo are valid by creating them in a NS.
    ns="test-yaml-ns"
    all_tasks="$*"
    ${KUBECTL_CMD} create ns "${ns}" || true

    local runtest
    for runtest in ${all_tasks}; do
        # remove task/ or stepaction/ from beginning
        local runtestdir=${runtest#*/}
        # remove /0.1/tests from end
        local testname=${runtestdir%%/*}
        runtest=${runtest//tests}

        # in case a stepaction/task is being removed then it's directory
        # doesn't exists, so skip the test for YAML
        [ ! -d "${runtest%%/*}/${testname}" ] && continue

        runtest="${runtest}${testname}.yaml"
        skipit=
        for ignore in ${TEST_YAML_IGNORES};do
            [[ ${ignore} == "${testname}" ]] && skipit=True
        done

        # don't test the stepactions/tasks which are deprecated
        cat ${runtest} | grep 'tekton.dev/deprecated: \"true\"' && skipit=True

        # In case if PLATFORM env variable is specified, do the tests only for matching stepactions/tasks
        [[ -n ${PLATFORM} ]] && [[ $(grep "tekton.dev/platforms" ${runtest} 2>/dev/null) != *"${PLATFORM}"* ]]  && skipit=True

        [[ -n ${skipit} ]] && continue
        echo "Checking ${testname}"
        ${KUBECTL_CMD} -n ${ns} apply -f <(sed "s/namespace:.*/namespace: ${ns}/" "${runtest}")
    done
}

function test_resource_creation() {
    local runtest
    declare -A resource_to_wait_for

    for runtest in $@;do
        # remove task/ from beginning
        local runtestdir=${runtest#*/}
        # remove /<version>/tests from end
        local testname=${runtestdir%%/*}
        local version=$(basename $(basename $(dirname $runtest)))
        # check version is in given format
        [[ ${version} =~ ^[0-9]+\.[0-9]+$ ]] || { echo "ERROR: version of the task is not set properly"; exit 1;}
        # replace . with - in version as not supported in namespace name
        version="$( echo $version | tr '.' '-' )"

        local tns="${testname}-${version}"
        #local tns=${TEST_NS}
        local skipit=

        for ignore in ${TEST_TASKRUN_IGNORES};do
            [[ ${ignore} == ${testname} ]] && skipit=True
        done

        # remove /tests from end
        local resourcedir=${runtest%/*}
        
        # check whether tests folder exists or not inside task dir
        # if not then run the tests for next task (if any)
        [[ ! -d $runtest ]] && skipit=True
        
        ls ${resourcedir}/*.yaml 2>/dev/null >/dev/null || skipit=True

        cat ${resourcedir}/*.yaml | grep 'tekton.dev/deprecated: \"true\"' && skipit=True

         # In case if PLATFORM env variable is specified, do the tests only for matching tasks
	    [[ -n ${PLATFORM} ]] && [[ $(grep "tekton.dev/platforms" ${resourcedir}/*.yaml 2>/dev/null) != *"${PLATFORM}"* ]] && skipit=True

	    [[ -n ${skipit} ]] && continue

        # In case of rerun it's fine to ignore this error
        ${KUBECTL_CMD} create namespace ${tns} >/dev/null 2>/dev/null || :

         # Install the task itself first. We can only have one YAML file
        yaml=$(printf  ${resourcedir}/*.yaml)
        started=$(date '+%Hh%M:%S')
        echo "${started} STARTING: ${testname}/${version}"

        # dry-run this YAML to validate and also get formatting side-effects.
        ${KUBECTL_CMD} -n ${tns} create -f ${yaml} --dry-run=client -o yaml >${TMPF}
        [[ -f ${resourcedir}/tests/pre-apply-task-hook.sh ]] && source ${resourcedir}/tests/pre-apply-task-hook.sh
        function_exists pre-apply-task-hook && pre-apply-task-hook

        [[ -d ${resourcedir}/tests/fixtures ]] && {
            # Create a configmap to make every file under fixture
            # available to the sidecar.
            ${KUBECTL_CMD} -n ${tns} create configmap fixtures --from-file=${resourcedir}/tests/fixtures
            # The task may already have a volumes section and in that case, we
            # need to append fixtures volume.
            if [[ -n $(grep "^[[:space:]]\{2,\}volumes:$" ${TMPF}) ]]; then
              sed -i "s/^[[:space:]]\{2,\}volumes:$/  volumes:\\n  - name: fixtures\\n    configMap:\\n      name: fixtures/g" ${TMPF} 
            else
              cat <<EOF >>${TMPF}
  volumes:
  - name: fixtures
    configMap:
      name: fixtures
EOF
            fi
            cat <<EOF >>${TMPF}
  sidecars:
  - image: gcr.io/tekton-releases/dogfooding/go-rest-api-test:latest
    name: go-rest-api
    volumeMounts:
    - name: fixtures
      mountPath: /fixtures
    env:
      - name: CONFIG
        value: |
$(cat ${resourcedir}/tests/fixtures/*.yaml|sed 's/^/          /')
EOF
        }

        # Make sure we have deleted the content, this is in case of rerun
        # and namespace hasn't been cleaned up or there is some Cluster*
        # stuff, which really should not be allowed.
        ${KUBECTL_CMD} -n ${tns} delete -f ${TMPF} >/dev/null 2>/dev/null || true
        ${KUBECTL_CMD} -n ${tns} create -f ${TMPF}

        # Install resource and run
        for yaml in ${runtest}/*.yaml;do
            cp ${yaml} ${TMPF}
            #[[ -f ${resourcedir}/tests/pre-apply-taskrun-hook.sh ]] && source ${resourcedir}/tests/pre-apply-taskrun-hook.sh
            #function_exists pre-apply-taskrun-hook && pre-apply-taskrun-hook

            # Make sure we have deleted the content, this is in case of rerun
            # and namespace hasn't been cleaned up or there is some Cluster*
            # stuff, which really should not be allowed.
            ${KUBECTL_CMD} -n ${tns} delete -f ${TMPF} >/dev/null 2>/dev/null || true
            ${KUBECTL_CMD} -n ${tns} create -f ${TMPF}
        done

        resource_to_wait_for["$testname/${version}"]="${tns}|$started"

    done

    # I would refactor this to a function but bash limitation is too great, really need a rewrite the sooner
    # the uglness to pass a hashmap to a function https://stackoverflow.com/a/17557904/145125
    local cnt=0
    local all_status=''
    local reason=''
    local maxloop=60 # 10 minutes max

    set +x
    while true;do
        # If we have timed out then show failures of what's remaining in
        # resource_to_wait_for we assume only first one fails this
        [[ ${cnt} == "${maxloop}" ]] && {
            for testname in "${!resource_to_wait_for[@]}";do
                target_ns=${resource_to_wait_for[$testname]}
                show_failure "${testname}" "${target_ns}"
            done
        }
        [[ -z ${resource_to_wait_for[*]} ]] && {
            break
        }

        for testname in "${!resource_to_wait_for[@]}";do
            target_ns=${resource_to_wait_for[$testname]%|*}
            started=${resource_to_wait_for[$testname]#*|}
            # sometimes we don't get all_status and reason in one go so
            # wait until we get the reason and all_status for 5 iterations
            for tektontype in pipelinerun taskrun;do
                for _ in {1..10}; do
                    all_status=$(${KUBECTL_CMD} get -n ${target_ns} ${tektontype} --output=jsonpath='{.items[*].status.conditions[*].status}')
                    reason=$(${KUBECTL_CMD} get -n ${target_ns} ${tektontype} --output=jsonpath='{.items[*].status.conditions[*].reason}')
                    [[ ! -z ${all_status} ]] && [[ ! -z ${reason} ]] && break
                    sleep 1
                done
                # No need to check taskrun if pipelinerun has been set
                [[ ! -z ${all_status} ]] && [[ ! -z ${reason} ]] && break
            done

            if [[ -z ${all_status} || -z ${reason} ]];then
                echo "Could not find a created taskrun or pipelinerun in ${target_ns}"
            fi

            breakit=True
            for status in ${all_status};do
                [[ ${status} == *ERROR || ${reason} == *Fail* || ${reason} == Couldnt* ]] && show_failure ${testname} ${target_ns}

                if [[ ${status} != True ]];then
                    breakit=
                fi
            done

            if [[ ${breakit} == True ]];then
                unset resource_to_wait_for[$testname]
                [[ -z ${CATALOG_TEST_SKIP_CLEANUP} ]] && ${KUBECTL_CMD} delete ns ${target_ns} >/dev/null
                echo "${started}::$(date '+%Hh%M:%S') SUCCESS: ${testname} testrun has successfully executed" ;
            fi

        done

        sleep 10
        cnt=$((cnt+1))
    done
    set -x
}
#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

eval "$(shellspec - -c) exit 1"

task_path=clair-scan.yaml

if [[ -f "../${task_path}" ]]; then
    task_path="../${task_path}"
fi


extract_script() {
  script="$(mktemp --tmpdir script_XXXXXXXXXX.sh)"
  yq -r ".spec.steps[] | select(.name == \"$1\").script" "${task_path}"  > "${script}"
  chmod +x "${script}"

  echo "${script}"
}

# array containing files/directories to remove on test exit
cleanup=()
trap 'rm -rf "${cleanup[@]}"' EXIT

# Extract the get-vulnerabilities Step script so we can test it
get_vulnerabilities_script="$(extract_script get-vulnerabilities)"
cleanup+=("${get_vulnerabilities_script}")

testdir() {
    testdir="$(mktemp -d)" && cleanup+=("${testdir}") && cd "${testdir}"

    AfterEach 'rm -rf "$testdir"'
}

clair_report() {
    echo "report --image-ref=registry.io/repository/image@$1 --db-path=/tmp/matcher.db --format=$2"
}


Describe "get vulnerabilities"
    BeforeEach testdir

    export IMAGE_URL=registry.io/repository/image:tag
    export IMAGE_DIGEST=sha256:f0cacc1a

    It "generates reports and images-processed.json"
        Mock clair-action
            clair_action_args+=("$*")
            %preserve clair_action_args
            # expecting the --format parameter to be the last one
            echo "report in ${clair_action_args[-1]#*--format=} format"
        End
        echo "sha256:f0cacc1a" > image-manifest-amd64.sha
        echo "sha256:cc1af0ca" > image-manifest-arm64.sha

        When call "${get_vulnerabilities_script}"
        The output should eq "Running clair-action on amd64 image manifest.
report in quay format
Running clair-action on arm64 image manifest.
report in quay format"
        The contents of file "images-processed.json" should equal '{"image": {"pullspec": "registry.io/repository/image:tag", "digests": ["sha256:f0cacc1a","sha256:cc1af0ca"]}}'
        The contents of file "clair-result-amd64.json" should equal 'report in quay format'
        The contents of file "clair-report-amd64.json" should equal 'report in clair format'
        The contents of file "clair-result-arm64.json" should equal 'report in quay format'
        The contents of file "clair-report-arm64.json" should equal 'report in clair format'
        The variable clair_action_args[@] should eq "$(clair_report sha256:f0cacc1a quay) "\
"$(clair_report sha256:f0cacc1a clair) "\
"$(clair_report sha256:cc1af0ca quay) "\
"$(clair_report sha256:cc1af0ca clair)"
    End

    It "fails in clair-action quay report"
        Mock clair-action
            clair_action_args+=("$*")
            %preserve clair_action_args
            [[ "$*" == *--format=quay* ]] && echo "didn't work out" && exit 1
        End
        echo "sha256:f0cacc1a" > image-manifest-amd64.sha

        When call "${get_vulnerabilities_script}"
        The output should eq "Running clair-action on amd64 image manifest.
didn't work out"
        The contents of file "images-processed.json" should equal '{"image": {"pullspec": "registry.io/repository/image:tag", "digests": ["sha256:f0cacc1a"]}}'
        The contents of file "clair-result-amd64.json" should equal "didn't work out"
        The file "clair-report-amd64.json" should not exist
        The variable clair_action_args[@] should eq "$(clair_report sha256:f0cacc1a quay)"
    End
End

# Extract the oci-attach-report Step script so we can test it
oci_attach_report_script="$(extract_script oci-attach-report)"
cleanup+=("${oci_attach_report_script}")

oras_attach() {
    echo "attach --no-tty --format go-template={{.digest}} --registry-config $HOME/auth.json --artifact-type application/vnd.redhat.clair-report+json registry.io/repository/image@$1 $2:application/vnd.redhat.clair-report+json"
}

Describe "OCI attach report"
    BeforeEach testdir

    export IMAGE_URL=registry.io/repository/image:tag

    It "skips attachments if no reports generated"
        Mock select-oci-auth
            echo select-oci-auth should not be called
        End

        Mock oras
            echo oras should not be called
        End

        When call "${oci_attach_report_script}"
        The output should eq "No Clair reports generated. Skipping upload."
    End

    It "attaches for single architecture"
        export HOME="${testdir}"

        Mock select-oci-auth
            echo selected auth
        End

        Mock oras
            oras_args+=("$*")
            %preserve oras_args
            echo report-digest
        End

        echo "sha256:f0cacc1a" > image-manifest-amd64.sha
        touch clair-report-amd64.json

        When call "${oci_attach_report_script}"
        The output should eq "Selecting auth
Attaching clair-report-amd64.json to registry.io/repository/image@sha256:f0cacc1a"
        The contents of file "auth.json" should equal "selected auth"
        The variable oras_args[@] should eq "$(oras_attach sha256:f0cacc1a clair-report-amd64.json)"
        The contents of file "reports.json" should equal '{"sha256:f0cacc1a":"report-digest"}'
    End

    It "attaches for multiple architecture"
        export HOME="${testdir}"

        Mock select-oci-auth
            echo selected auth
        End

        Mock oras
            oras_args+=("$*")
            %preserve oras_args
            for a in "$@"; do
                if [[ "$a" == *@sha256:* ]]; then
                    echo "sha256:$(echo "${a/*@sha256:/}" | rev)"
                    break
                fi
            done
        End

        echo "sha256:f0cacc1a" > image-manifest-amd64.sha
        echo "sha256:cc1af0ca" > image-manifest-arm64.sha
        echo "sha256:f01acacc" > image-manifest-ppc64le.sha
        touch clair-report-{amd64,arm64,ppc64le}.json

        When call "${oci_attach_report_script}"
        The output should eq "Selecting auth
Attaching clair-report-amd64.json to registry.io/repository/image@sha256:f0cacc1a
Attaching clair-report-arm64.json to registry.io/repository/image@sha256:cc1af0ca
Attaching clair-report-ppc64le.json to registry.io/repository/image@sha256:f01acacc"
        The contents of file "auth.json" should equal "selected auth"
        The variable oras_args[@] should eq "$(oras_attach sha256:f0cacc1a clair-report-amd64.json) "\
"$(oras_attach sha256:cc1af0ca clair-report-arm64.json) "\
"$(oras_attach sha256:f01acacc clair-report-ppc64le.json)"
        The contents of file "reports.json" should equal '{"sha256:f0cacc1a":"sha256:a1ccac0f","sha256:cc1af0ca":"sha256:ac0fa1cc","sha256:f01acacc":"sha256:ccaca10f"}'
    End
End

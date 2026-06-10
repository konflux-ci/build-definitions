package main

import "testing"

func TestIsBuildTrustedArtifactsImage(t *testing.T) {
	tests := []struct {
		image string
		want  bool
	}{
		{
			image: "quay.io/konflux-ci/build-trusted-artifacts@sha256:9bd32f6bafb517b309e11a2d89365052b4ab3f1c9c23c4ffd45aff6f03960476",
			want:  true,
		},
		{
			image: "quay.io/konflux-ci/build-trusted-artifacts:latest@sha256:9bd32f6bafb517b309e11a2d89365052b4ab3f1c9c23c4ffd45aff6f03960476",
			want:  true,
		},
		{
			image: "quay.io/konflux-ci/buildah-task@sha256:4c470b5a153c4acd14bf4f8731b5e36c61d7faafe09c2bf376bb81ce84aa5709",
			want:  false,
		},
		{
			image: "quay.io/konflux-ci/build-trusted-artifacts:latest",
			want:  true,
		},
		{
			image: "not-an-image-reference",
			want:  false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.image, func(t *testing.T) {
			if got := isBuildTrustedArtifactsImage(tt.image); got != tt.want {
				t.Fatalf("isBuildTrustedArtifactsImage(%q) = %v, want %v", tt.image, got, tt.want)
			}
		})
	}
}

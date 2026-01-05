#!/bin/bash

echo "Reducing computeResources for task: $1"
yq -i eval '.spec.steps[].computeResources = {}' "$1"


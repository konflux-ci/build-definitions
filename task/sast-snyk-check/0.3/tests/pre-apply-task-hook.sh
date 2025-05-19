#!/bin/bash

echo "Removing computeResources for task: $1"
yq -i eval '.spec.steps[0].computeResources = {}' $1
yq -i eval '.spec.steps[1].computeResources = {}' $1

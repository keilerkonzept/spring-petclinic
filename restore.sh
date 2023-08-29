#!/usr/bin/env bash
set -e

readonly org=keilerkonzept
readonly repo=petclinic-on-crac

docker run --rm -p 8080:8080 --name $repo $org/$repo:checkpoint

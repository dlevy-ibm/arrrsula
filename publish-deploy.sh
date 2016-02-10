#!/bin/bash

set -e

source project-list.sh

BASEDIR=$(pwd)/openstack

cd $BASEDIR

# Update pyrrrat/openstack with pure upstream
git push origin master

# Record the successful state into the repo that is good to pull from
for project in $LOCAL_PROJECTS ; do
    pushd $project
    git push -f pyrrrat HEAD:pyrrrat/deploy
    popd
done

git push -f origin HEAD:pyrrrat/deploy

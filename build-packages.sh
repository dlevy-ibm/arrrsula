#!/bin/bash

set -ex

source project-list.sh
BASEDIR=$(pwd)/openstack

pushd $BASEDIR/ovs

fakeroot debian/rules clean
git clean -f 

DEB_BUILD_OPTIONS=nocheck fakeroot debian/rules binary

popd

pushd $BASEDIR

sudo mkdir -p /srv/artifacts
sudo chown jenkins:jenkins /srv/artifacts
OVSCOMMON=$(ls openvswitch-common*)
OVSVERS=$(echo $OVSCOMMON | cut -d"-" -f3 | cut -d "_" -f1)
mkdir -p /srv/artifacts/ovs-$OVSVERS
rsync -avHz *.deb /srv/artifacts/ovs-$OVSVERS

popd

#!/bin/bash

set -ex

source project-list.sh
BASEDIR=$(pwd)/openstack

pushd $BASEDIR/ovs

fakeroot debian/rules clean
git clean -f 

DEB_BUILD_OPTIONS=nocheck fakeroot debian/rules binary

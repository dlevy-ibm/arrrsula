#!/bin/bash

set -ex

source project-list.sh
BASEDIR=$(pwd)/openstack

sudo apt-get update
sudo apt-get install -y build-essential fakeroot graphviz python-all \
    python-qt4 python-twisted-conch dch devscripts pkg-components \
    quilt dh-make-perl dh-autoreconf libssl-dev

#!/usr/bin/env bash

set -x

ansible all "$@" -m shell -a 'sudo -i apt-get -qq update && sudo -i DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Options::=--force-confold -y --with-new-pkgs upgrade'

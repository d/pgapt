#!/usr/bin/make -f
# -*- makefile -*-
#
# scripts to build postgresql debian packages
# and extensions too

# where to build
OUT  = /var/cache/pbuilder/build/pg
REL  = $(shell lsb_release -sc)
ARCH = $(shell dpkg --print-architecture)

VERSIONS = 8.3 8.4 9.0 9.1

build-depends:
	sudo apt-get install bzr wget bzip2 tar gawk lsb-release
	for v in $(VERSIONS); do \
		sudo apt-get build-dep postgresql-$$v; \
	done

setup:
	make -C debian $@

postgresql-%: setup
	mkdir -p $(OUT)/$(REL)/$(ARCH)
	make OUT=$(OUT)/$(REL)/$(ARCH) -C pgsql $@

postgresql: postgresql-8.4 postgresql-9.0 postgresql-9.1



#!/bin/sh

# union-type=overlay needs Linux 4.x and schroot >= 1.6.10-2~.

# ./schroot-config.sh | sudo tee /etc/schroot/chroot.d/sbuild.conf

set -eu

for dist in sid jessie wheezy squeeze utopic trusty precise; do
	for arch in amd64 i386; do
		cat <<-EOF
		[$dist-pgdg-$arch-sbuild]
		aliases=$dist-$arch
		type=directory
		groups=sbuild
		root-groups=sbuild
		source-groups=sbuild
		source-root-groups=sbuild
		directory=/home/chroot/$dist-$arch
		union-type=overlay
		union-overlay-directory=/var/run
		profile=sbuild
		EOF
		[ $arch = i386 ] && echo "personality=linux32"
		echo
	done
done

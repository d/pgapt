#!/bin/sh

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
		#union-type=overlay # linux 4+
		union-type=aufs
		union-overlay-directory=/var/run
		profile=sbuild
		EOF
		[ $arch = i386 ] && echo "personality=linux32"
		echo
	done
done

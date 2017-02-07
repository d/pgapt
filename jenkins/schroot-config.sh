#!/bin/sh

# union-type=overlay needs Linux 4.x and schroot >= 1.6.10-2~.

# ./schroot-config.sh | sudo tee /etc/schroot/chroot.d/sbuild.conf

set -eu

ARCH=$(dpkg --print-architecture)

case $ARCH in
	amd64) ARCH="amd64 i386"
		DISTS="sid stretch jessie wheezy zesty xenial trusty precise" ;;
	ppc64el)
		DISTS="sid stretch jessie        zesty xenial trusty" ;;
esac

for dist in $DISTS; do
	for arch in $ARCH; do
		body="$(cat <<-EOF
			type=directory
			groups=sbuild
			root-groups=sbuild
			source-groups=sbuild
			source-root-groups=sbuild
			directory=/home/chroot/$dist-$arch
			union-type=overlay
			union-overlay-directory=/var/run
			EOF
			[ $arch = i386 ] && echo "personality=linux32"
			echo
		)"

		echo "[$dist-$arch]"
		aliases="$dist"
		[ $dist = sid ] && [ $arch = amd64 ] && aliases="$aliases,default"
		[ $arch = amd64 ] && echo "aliases=$aliases"
		echo "$body"
		echo

		echo "[$dist-pgdg-$arch-sbuild]"
		[ $dist = sid ] && echo "aliases=unstable-$arch-sbuild,experimental-$arch-sbuild"
		echo "profile=sbuild"
		echo "$body"
		echo
	done
done

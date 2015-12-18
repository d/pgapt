#!/bin/sh

# union-type=overlay needs Linux 4.x and schroot >= 1.6.10-2~.

# ./schroot-config.sh | sudo tee /etc/schroot/chroot.d/sbuild.conf

set -e

DISTS=$(perl -e 'use YAML::Syck;
	$y = LoadFile("pgapt-jobs.yaml");
	@d = grep { exists $_->{yamltemplates} } @$y;
	print "@{$d[0]->{yamltemplates}->{dist_axis}->{values}}";'
)

for dist in $DISTS; do
	for arch in amd64 i386; do
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
		[ $arch = amd64 ] && echo "aliases=$dist"
		echo "$body"
		echo

		echo "[$dist-pgdg-$arch-sbuild]"
		[ $dist = sid ] && echo "aliases=unstable-$arch-sbuild,experimental-$arch-sbuild"
		echo "profile=sbuild"
		echo "$body"
		echo
	done
done

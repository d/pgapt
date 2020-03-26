#!/bin/sh

# union-type=overlay needs Linux 4.x and schroot >= 1.6.10-2~.

# ./schroot-config.sh | sudo tee /etc/schroot/chroot.d/sbuild.conf

set -eu

# seed PG_SUPPORTED_DISTS if pgapt.conf is not yet installed
PG_SUPPORTED_DISTS="sid"

# read pgapt config
for dir in . .. /home/jenkins/jenkins/workspace/apt.postgresql.org /home/buildd/workspace/apt.postgresql.org; do
  test -f $dir/pgapt.conf || continue
  . $dir/pgapt.conf
  break
done

case $(dpkg --print-architecture) in
	amd64) ARCHS="amd64 i386" ;;
	arm64) ARCHS="arm64" ;;
	ppc64el) ARCHS="ppc64el" ;;
esac

for dist in $PG_SUPPORTED_DISTS; do
	for arch in $ARCHS; do

		# if arguments are given, execute as command in enviroment
		# ./schroot-config.sh ./sbuild-update.sh
		if [ "$*" ]; then
			echo "### distribution=$dist architecture=$arch ###"
			export distribution=$dist architecture=$arch
			"$@"
			continue
		fi

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

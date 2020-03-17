#!/bin/sh

set -eu

DISTRIBUTIONS="sid bullseye buster stretch jessie wheezy
	focal eoan disco bionic xenial trusty precise"
FLAVORS="pgdg pgdg-testing"

for DIST in $DISTRIBUTIONS ; do
	for FLAVOR in $FLAVORS ; do
		D="$DIST-$FLAVOR"
		case $DIST in
			# Debian
			wheezy) ARCHS="amd64 i386"
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4 9.5 9.6 10" ;;
			jessie) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main         8.4 9.0 9.1 9.2 9.3 9.4 9.5 9.6 10 11 12" ;;
			stretch) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main                     9.2 9.3 9.4 9.5 9.6 10 11 12 13" ;;
			buster) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main                         9.3 9.4 9.5 9.6 10 11 12 13" ;;
			bullseye) ARCHS="amd64 ppc64el"
				COMPONENTS="main                             9.4 9.5 9.6 10 11 12" ;;
			sid)    ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4 9.5 9.6 10 11 12 13" ;;
			# Ubuntu
			precise) ARCHS="amd64 i386"
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4 9.5 9.6" ;;
			trusty) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main         8.4 9.0 9.1 9.2 9.3 9.4 9.5 9.6 10 11" ;;
			xenial) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main                 9.1 9.2 9.3 9.4 9.5 9.6 10 11 12 13" ;;
			bionic) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main                         9.3 9.4 9.5 9.6 10 11 12 13" ;;
			disco)  ARCHS="amd64"
				COMPONENTS="main                             9.4 9.5 9.6 10 11 12" ;;
			eoan)   ARCHS="amd64"
				COMPONENTS="main                             9.4 9.5 9.6 10 11 12" ;;
			focal)  ARCHS="amd64 ppc64el"
				COMPONENTS="main                             9.4 9.5 9.6 10 11 12 13" ;;
			*)
				echo "$D missing in COMPONENTS list" >&2
				exit 1 ;;
		esac
		COMPONENTS=$(echo $COMPONENTS) # strip duplicate spaces
		cat <<EOF
Codename: $D
Suite: $D
Origin: apt.postgresql.org
Label: PostgreSQL for Debian/Ubuntu repository
Architectures: source $ARCHS
Components: $COMPONENTS
SignWith: ACCC4CF8
Log: $D.log
Uploaders: uploaders
DebIndices: Packages Release . .gz .bz2
UDebIndices: Packages . .gz .bz2
DscIndices: Sources Release .gz .bz2
Tracking: minimal includebuildinfos keepsources
Contents: percomponent nocompatsymlink
EOF
		case $FLAVOR in *testing)
			echo "NotAutomatic: yes"
			echo "ButAutomaticUpgrades: yes"
			;;
		esac
		echo
	done
done

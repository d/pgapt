#!/bin/sh

DISTRIBUTIONS="sid buster stretch jessie wheezy squeeze lenny etch
	bionic zesty xenial wily utopic trusty saucy precise lucid"
FLAVORS="pgdg pgdg-testing"

for DIST in $DISTRIBUTIONS ; do
	for FLAVOR in $FLAVORS ; do
		D="$DIST-$FLAVOR"
		ARCHS="amd64 i386"
		case $DIST in
			# Debian
			lenny|etch)
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2" ;;
			squeeze)
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4 9.5" ;;
			wheezy)
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4 9.5 9.6 10" ;;
			jessie) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main         8.4 9.0 9.1 9.2 9.3 9.4 9.5 9.6 10 11" ;;
			stretch) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main                     9.2 9.3 9.4 9.5 9.6 10 11 12" ;;
			buster) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main                         9.3 9.4 9.5 9.6 10 11 12" ;;
			sid)    ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4 9.5 9.6 10 11 12" ;;
			# Ubuntu
			lucid)
				COMPONENTS="main     8.3 8.4 9.0 9.1 9.2 9.3 9.4" ;;
			precise)
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4 9.5 9.6" ;;
			saucy)
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4" ;;
			trusty) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main         8.4 9.0 9.1 9.2 9.3 9.4 9.5 9.6 10 11" ;;
			utopic)
				COMPONENTS="main         8.4 9.0 9.1 9.2 9.3 9.4 9.5" ;;
			wily)
				COMPONENTS="main                 9.1 9.2 9.3 9.4 9.5 9.6" ;;
			xenial) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main                 9.1 9.2 9.3 9.4 9.5 9.6 10 11 12" ;;
			zesty) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main                     9.2 9.3 9.4 9.5 9.6 10" ;;
			bionic) ARCHS="amd64 i386 ppc64el"
				COMPONENTS="main                         9.3 9.4 9.5 9.6 10 11 12" ;;
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

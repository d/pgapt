#!/bin/sh

DISTRIBUTIONS="sid jessie wheezy squeeze lenny etch
	utopic trusty saucy precise lucid"
FLAVORS="pgdg pgdg-testing pgdg-deprecated"

for DIST in $DISTRIBUTIONS ; do
	for FLAVOR in $FLAVORS ; do
		D="$DIST-$FLAVOR"
		case $DIST in
			lenny|etch)
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2" ;;
			lucid)
				COMPONENTS="main 8.3 8.4 9.0 9.1 9.2 9.3 9.4" ;;
			utopic|trusty)
				COMPONENTS="main 8.4 9.0 9.1 9.2 9.3 9.4" ;;
			wheezy|squeeze|saucy|precise)
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4" ;;
			jessie)
				COMPONENTS="main 9.0 9.1 9.2 9.3 9.4" ;;
			sid)
				COMPONENTS="main 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4 9.5" ;;
			*)
				echo "$D missing in COMPONENTS list" >&2
				exit 1 ;;
		esac
		cat <<EOF
Codename: $D
Suite: $D
Origin: apt.postgresql.org
Label: PostgreSQL for Debian/Ubuntu repository
Architectures: source amd64 i386
Components: $COMPONENTS
SignWith: ACCC4CF8
Log: $D.log
Uploaders: uploaders
DebIndices: Packages Release . .gz .bz2
UDebIndices: Packages . .gz .bz2
DscIndices: Sources Release .gz .bz2
Tracking: all
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

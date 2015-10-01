#!/bin/sh

error () {
  echo "Error: $@" >&2
  exit 1
}

# check if chroot exists
schroot -l | grep -q source:$distribution-$architecture-sbuild || \
  error "There is no schroot definition for source:$distribution-$architecture-sbuild"

set -eux

deb="http://deb/debian"
apt1="http://apt.postgresql.org/pub/repos/apt"
apt2="http://atalia.postgresql.org/pub/repos/apt"
case $(hostname) in
  pgdg*) # use local cache on build host
    deb="http://debian-approx:9999/debian"
    apt1="http://atalia-approx:9999/atalia"
    apt1="$apt1"
    ;;
esac

PGDG_SH=$(mktemp /tmp/pgdg.XXXXXX.sh)
trap "rm -f $PGDG_SH" 0 2 3 15
cat < /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh > $PGDG_SH

# build package and run autopkgtests inside the chroot
# (lock against concurrent apt-get update/upgrade operations and builds)
LOCKDIR="/var/lock/sbuild-package"
if ! test -d $LOCKDIR; then
  mkdir $LOCKDIR
  chgrp sbuild $LOCKDIR
  chmod 3775 $LOCKDIR
fi
umask 002

(
  flock --exclusive 9
  cd /
  schroot -u root -c source:$distribution-$architecture-sbuild -- sh <<-EOF
	set -ex
	
	if ! test -f /etc/apt/sources.list.d/pgdg.list; then
		chmod +x $PGDG_SH
		echo yes | $PGDG_SH
	fi
	echo "deb $apt1 $distribution-pgdg main" > /etc/apt/sources.list.d/pgdg.list
	echo "deb $apt2 $distribution-pgdg-testing main" >> /etc/apt/sources.list.d/pgdg.list
	case $distribution in
	  squeeze) echo "deb $deb-backports/ $distribution-backports main" \
	    > /etc/apt/sources.list.d/backports.list ;;
	  wheezy) echo "deb $deb $distribution-backports main" \
	    > /etc/apt/sources.list.d/backports.list ;;
	esac
	apt-get update
	
	apt-get -y -o DPkg::Options::=--force-confnew install eatmydata
	case $distribution in
	  squeeze) eatmydata apt-get -y -o DPkg::Options::=--force-confnew install debhelper/${distribution}-backports ;;
	esac
	eatmydata apt-get -y -o DPkg::Options::=--force-confnew install pgdg-buildenv
	eatmydata apt-get -y -o DPkg::Options::=--force-confnew dist-upgrade
	apt-get clean
	
	dpkg -l 'libpq*' 'newpid' 'pgdg*' 'postgresql*' || :
	EOF
) 9> $LOCKDIR/$distribution-$architecture.lock

#!/bin/sh

set -eu

error () {
  echo "Error: $@" >&2
  exit 1
}

# use "default" chroot here ("sbuild" doesn't get /etc/hosts copied)
chroot="source:$distribution-$architecture"

# check if chroot exists
schroot -l | grep -q $chroot || \
  error "There is no schroot definition for $chroot"

apt1="http://apt.postgresql.org/pub/repos/apt"
apt2="http://atalia.postgresql.org/pub/repos/apt"
ubuntu="http://de.archive.ubuntu.com/ubuntu"
case $(hostname) in
  pgdg*) # use local cache on build host
    apt1="http://atalia-approx:9999/atalia"
    apt2="$apt1"
    ubuntu="http://ubuntu-approx:9999/ubuntu"
    ;;
esac

# enable backports
deb="http://deb/debian"
case $(hostname) in
  pgdg*) # use local cache on build host
    deb="http://debian-approx:9999/debian" ;;
esac
case $distribution in
  squeeze) BACKPORTS="deb $deb-backports/ $distribution-backports main" ;;
  wheezy|jessie) BACKPORTS="deb $deb $distribution-backports main" ;;
esac

PGDG_SH=$(mktemp /var/tmp/pgdg.XXXXXX.sh)
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
  cd /
  set -x
  flock --exclusive 9
  schroot -u root -c $chroot -- sh <<-EOF
	set -ex
	
	if ! test -f $PGDG_SH; then
		echo "$PGDG_SH not found in the chroot, did you configure a /var/tmp bindmount?"
		exit 1
	fi
	if ! test -f /etc/apt/sources.list.d/pgdg.list; then
		chmod +x $PGDG_SH
		echo yes | $PGDG_SH
	fi

	test -e /etc/dpkg/dpkg.cfg.d/01unsafeio || echo force-unsafe-io | tee /etc/dpkg/dpkg.cfg.d/01unsafeio
	test -e /etc/apt/apt.conf.d/20norecommends || echo 'APT::Install-Recommends "false";' | tee /etc/apt/apt.conf.d/20norecommends
	test -e /etc/apt/apt.conf.d/50i18n || echo 'Acquire::Languages { none; };' | tee /etc/apt/apt.conf.d/50i18n
	rm -f /var/lib/apt/lists/*_Translation-*

	# write sources lists
	echo "deb $apt1 $distribution-pgdg main" > /etc/apt/sources.list.d/pgdg.list
	echo "deb $apt2 $distribution-pgdg-testing main" >> /etc/apt/sources.list.d/pgdg.list
	case $distribution in
	  precise|trusty|wily|xenial) # libossp-uuid is in universe on vivid+
	    echo "deb $ubuntu $distribution universe" > /etc/apt/sources.list.d/universe.list ;;
	esac
	if [ "${BACKPORTS:-}" ]; then
	  echo "${BACKPORTS:-}" > /etc/apt/sources.list.d/backports.list
	  if [ -d /var/lib/apt/backports ]; then
	    cp -al /var/lib/apt/backports/* /var/lib/apt/lists
	  fi
	fi

	# tell ucf not to ask any questions
	export UCF_FORCE_CONFFNEW=y UCF_FORCE_CONFFMISS=y

	apt-get update

	# save backports lists
	rm -rf /var/lib/apt/backports /etc/apt/sources.list.d/backports.list.disabled
	if [ "${BACKPORTS:-}" ]; then
	  mv /etc/apt/sources.list.d/backports.list /etc/apt/sources.list.d/backports.list.disabled
	  mkdir -p /var/lib/apt/backports
	  mv /var/lib/apt/lists/*backports* /var/lib/apt/backports
	fi
	
	[ -x /usr/bin/eatmydata ] && eatmydata="eatmydata"
	#case $distribution in
	#  squeeze) \$eatmydata apt-get -y -o DPkg::Options::=--force-confnew install debhelper/${distribution}-backports ;;
	#esac
	\$eatmydata apt-get -y -o DPkg::Options::=--force-confnew install pgdg-buildenv
	eatmydata apt-get -y -o DPkg::Options::=--force-confnew dist-upgrade
	apt-get clean
	
	dpkg -l 'libpq*' 'newpid' 'pgdg*' 'postgresql*' || :
	EOF
) 9> $LOCKDIR/$distribution-$architecture.lock

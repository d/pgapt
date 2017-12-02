#!/bin/sh

set -eu

error () {
  echo "Error: $@" >&2
  exit 1
}

# read pgapt config
for dir in . .. /home/jenkins/jenkins/workspace/apt.postgresql.org /home/buildd/workspace/apt.postgresql.org; do
  test -f $dir/pgapt.conf || continue
  . $dir/pgapt.conf
  break
done
set_dist_vars $distribution

# use "default" chroot here ("sbuild" doesn't get /etc/hosts copied)
chroot="source:$distribution-$architecture"
chroot_path="/home/chroot/$distribution-$architecture"

# check if chroot is configured in sbuild
schroot -l | grep -q $chroot || \
  error "There is no schroot definition for $chroot (run schroot-config.sh first)"

apt1="http://apt.postgresql.org/pub/repos/apt"
apt2="http://atalia.postgresql.org/pub/repos/apt"
ubuntu="http://de.archive.ubuntu.com/ubuntu"
case $(hostname) in
  pgdg*|benz*) # use local cache on build host
    apt1="http://atalia-approx:9999/atalia"
    apt2="$apt1"
    ubuntu="http://ubuntu-approx:9999/ubuntu"
    ;;
esac

# enable backports and security
deb="http://deb.debian.org/debian"
security="http://security.debian.org/debian-security"
case $(hostname) in
  pgdg*|benz*) # use local cache on build host
    deb="http://debian-approx:9999/debian"
    security="http://security-approx:9999/security"
    ;;
esac
if [ "$HAS_BACKPORTS" ]; then
  case $DISTRO in
    debian) BACKPORTS="deb $deb $distribution-backports main" ;;
    ubuntu) BACKPORTS="deb $ubuntu $distribution-backports main" ;;
  esac
fi

# mirror to use for debootstrap
case $DISTRO in
  ubuntu) mirror="$ubuntu" ;;
  *) mirror="$deb" ;;
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
  flock --exclusive 9 # lock against concurrent access

  # create chroot if it doesn't exist yet
  if ! test -d $chroot_path; then
    echo "Creating chroot in $chroot_path"
    if ! test -e /usr/share/debootstrap/scripts/$distribution; then
      case $DISTRO in
        debian) sudo ln -sv sid /usr/share/debootstrap/scripts/$distribution ;;
        ubuntu) sudo ln -sv gutsy /usr/share/debootstrap/scripts/$distribution ;;
      esac
    fi
    sudo debootstrap --variant=buildd --arch=$architecture $distribution $chroot_path $mirror
  fi

  # do the update
  schroot -u root -c $chroot -- sh <<-EOF
	set -ex
	
	# configure dpkg and apt
	test -e /etc/dpkg/dpkg.cfg.d/01unsafeio || echo force-unsafe-io | tee /etc/dpkg/dpkg.cfg.d/01unsafeio
	test -e /etc/apt/apt.conf.d/20norecommends || echo 'APT::Install-Recommends "false";' | tee /etc/apt/apt.conf.d/20norecommends
	test -e /etc/apt/apt.conf.d/50i18n || echo 'Acquire::Languages { none; };' | tee /etc/apt/apt.conf.d/50i18n
	rm -f /var/lib/apt/lists/*_Translation-*

	# run apt.postgresql.org.sh
	if ! test -f $PGDG_SH; then
		echo "$PGDG_SH not found in the chroot, did you configure a /var/tmp bindmount?"
		exit 1
	fi
	if ! test -f /etc/apt/sources.list.d/pgdg.list; then
		apt-get install -y gnupg
		chmod +x $PGDG_SH
		echo yes | $PGDG_SH
	fi

	# write sources lists
	echo "deb $mirror $distribution main" > /etc/apt/sources.list
	echo "deb $apt1 $distribution-pgdg main" > /etc/apt/sources.list.d/pgdg.list
	echo "deb $apt2 $distribution-pgdg-testing main" >> /etc/apt/sources.list.d/pgdg.list
	case $DISTRO in
	  ubuntu) # libossp-uuid-dev is in universe on vivid+
	    echo "deb $ubuntu $distribution universe" > /etc/apt/sources.list.d/universe.list
	    echo "deb $ubuntu $distribution-security main" > /etc/apt/sources.list.d/security.list
	    ;;
	  *)
	    [ "$distribution" != "sid" ] && echo "deb $security $distribution/updates main" > /etc/apt/sources.list.d/security.list
	    ;;
	esac
	if [ "${BACKPORTS:-}" ]; then
	  echo "${BACKPORTS:-}" > /etc/apt/sources.list.d/backports.list
	  if [ -d /var/lib/apt/backports ]; then
	    rm -f /var/lib/apt/lists/*backports* # clean up if last run failed
	    cp -al /var/lib/apt/backports/* /var/lib/apt/lists
	  fi
	fi

	# tell debconf and ucf not to ask any questions
	export DEBIAN_FRONTEND=noninteractive
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
	
	# remove libreadline-dev if present
	if dpkg -l 'libreadline*-dev' | grep -q '^ii'; then
	  apt-get remove -y 'libreadline*-dev'
	fi

	dpkg -l 'libpq*' 'newpid' 'pgdg*' 'postgresql*' 'libreadline*' 'libedit*' || :

	# don't create any cluster on PostgreSQL installation
	grep -q '^create_main_cluster = false' /etc/postgresql-common/createcluster.conf || sed -i -e 's/.*create_main_cluster.*/create_main_cluster = false/' /etc/postgresql-common/createcluster.conf

	:
	EOF
) 9> $LOCKDIR/$distribution-$architecture.lock

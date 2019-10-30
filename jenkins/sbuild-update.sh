#!/bin/sh

set -eu

error () {
  echo "Error: $@" >&2
  exit 1
}

# use "sbuild" chroot here (default bind-mounts /root)
chroot="source:${distribution:=sid}-pgdg-${architecture:=amd64}-sbuild"
chroot_path="/home/chroot/$distribution-$architecture"

# read pgapt config
for dir in . .. /home/jenkins/jenkins/workspace/apt.postgresql.org /home/buildd/workspace/apt.postgresql.org; do
  test -f $dir/pgapt.conf || continue
  . $dir/pgapt.conf
  break
done
set_dist_vars $distribution

# check if chroot is configured in sbuild
schroot -l | grep -q $chroot || \
  error "There is no schroot definition for $chroot (run schroot-config.sh first)"

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
	test -e /etc/apt/apt.conf.d/60releaseinfo || echo 'Acquire::AllowReleaseInfoChange "true" { Suite "true"; };' | tee /etc/apt/apt.conf.d/60releaseinfo # don't complain when testing gets released as stable
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
	echo "deb-src $mirror_src $distribution main" >> /etc/apt/sources.list
	echo "deb $apt1 $distribution-pgdg main" > /etc/apt/sources.list.d/pgdg.list
	echo "deb $apt2 $distribution-pgdg-testing main" >> /etc/apt/sources.list.d/pgdg.list
	echo "deb-src $apt2 $distribution-pgdg-testing main" >> /etc/apt/sources.list.d/pgdg.list
	case $DISTRO in
	  ubuntu) # libossp-uuid-dev is in universe on vivid+
	    echo "deb $mirror $distribution universe" > /etc/apt/sources.list.d/universe.list
	    echo "deb-src $mirror_src $distribution universe" >> /etc/apt/sources.list.d/universe.list
	    echo "deb $mirror $distribution-updates main universe" > /etc/apt/sources.list.d/updates.list
	    echo "deb-src $mirror_src $distribution-updates main universe" >> /etc/apt/sources.list.d/updates.list
	    echo "deb $mirror $distribution-security main universe" > /etc/apt/sources.list.d/security.list
	    echo "deb-src $mirror_src $distribution-security main universe" >> /etc/apt/sources.list.d/security.list
	    ;;
	  *)
	    if [ "${dist_security:-}" ]; then
	      echo "deb ${security:-} ${dist_security:-} main" > /etc/apt/sources.list.d/security.list
	      echo "deb-src ${security:-} ${dist_security:-} main" >> /etc/apt/sources.list.d/security.list
	    fi
	    ;;
	esac
	if [ "$HAS_BACKPORTS" ]; then
	  echo "${mirror_backports:-}" > /etc/apt/sources.list.d/backports.list
	  if [ -d /var/lib/apt/backports ]; then
	    rm -f /var/lib/apt/lists/*backports* # clean up if last run failed
	    cp -al /var/lib/apt/backports/* /var/lib/apt/lists
	  fi
	else
	  rm -f /etc/apt/sources.list.d/backports.list*
	fi

	# tell debconf and ucf not to ask any questions
	export DEBIAN_FRONTEND=noninteractive
	export UCF_FORCE_CONFFNEW=y UCF_FORCE_CONFFMISS=y

	# try update twice because ubuntu mirrors keep acting up
	apt-get -y update || { sleep 60; apt-get -y update; }

	# save backports lists
	rm -rf /var/lib/apt/backports /etc/apt/sources.list.d/backports.list.disabled
	if [ "$HAS_BACKPORTS" ]; then
	  # install lintian from backports (necessary because
	  # /usr/share/doc/lintian/lintian.html changes filetype in
	  # stretch/buster/bullseye, and upgrading on overlayfs fails)
	  apt-get -y install -t $distribution-backports lintian

	  mv /etc/apt/sources.list.d/backports.list /etc/apt/sources.list.d/backports.list.disabled
	  mkdir -p /var/lib/apt/backports
	  mv /var/lib/apt/lists/*backports* /var/lib/apt/backports
	fi
	
	[ -x /usr/bin/eatmydata ] && eatmydata="eatmydata"
	\$eatmydata apt-get -y -o DPkg::Options::=--force-confnew dist-upgrade
	#case $distribution in
	#  squeeze) \$eatmydata apt-get -y -o DPkg::Options::=--force-confnew install debhelper/${distribution}-backports ;;
	#esac
	# install llvm/clang (not in pgdg-buildenv because it's architecture-specific)
	case $distribution in
	  jessie) ;;
	  stretch|bionic|xenial)
	    case $architecture in amd64|i386) apt-get -y install llvm-6.0-dev clang-6.0 ;; esac ;;
	  buster|disco) apt-get -y install llvm-7-dev clang-7 ;;
	  *) apt-get -y install llvm-9-dev clang-9 libllvm7-;;
	esac
	# bionic-updates has libllvm7, but we don't want that yet (2019-09-03)
	[ "$distribution" = "bionic" ] && apt-get remove --purge -y libllvm7
	\$eatmydata apt-get -y -o DPkg::Options::=--force-confnew install pgdg-buildenv pgdg-keyring
	eatmydata apt-get -y autoremove --purge
	apt-get clean
	
	# remove libreadline-dev if present
	if dpkg -l 'libreadline*-dev' | grep -q '^ii'; then
	  apt-get remove -y 'libreadline*-dev'
	fi

	dpkg -l 'libpq*' 'newpid' 'pgdg*' 'postgresql*' 'libreadline*' 'libedit*' || :

	# don't create any cluster on PostgreSQL installation
	grep -q '^create_main_cluster = false' /etc/postgresql-common/createcluster.conf || sed -i -e 's/.*create_main_cluster.*/create_main_cluster = false/' /etc/postgresql-common/createcluster.conf

	# pre-generate autopkgtest signing key
	if ! test -f /root/.cache/autopkgtest/secring.gpg &&
	  dpkg --compare-versions \$(dpkg-query -W -f '\${Version}' autopkgtest) lt 3.16; then
	  umask 077
	  mkdir -p /root/.cache/autopkgtest
	  cd /root/.cache/autopkgtest
	  cat > key-gen-params <<-EOT
		Key-Type: DSA
		Key-Length: 1024
		Key-Usage: sign
		Name-Real: autopkgtest per-run key
		Name-Comment: do not trust this key
		Name-Email: autopkgtest@example.com
		EOT
	  gpg --homedir=/root/.cache/autopkgtest --batch --no-random-seed-file --gen-key key-gen-params
	fi

	EOF
) 9> $LOCKDIR/$distribution-$architecture.lock

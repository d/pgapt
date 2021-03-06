# apt.postgresql.org

The main idea of this project is to provide PostgreSQL and its Extensions
packages for all supported PostgreSQL versions and debian version. That
means things like PostgreSQL 9.1 for `squeeze`, with all known debian
extensions, and for `sid` and `wheezy` too. And same for `8.3` and `8.4` and
`9.0` and `9.1` and `9.2`. Targeting `i386` and `amd64`.

https://wiki.postgresql.org/wiki/Apt

## Build System

The build system is currently based on jenkins and some scripting. `Jenkins`
is only about launching the build jobs, the real work is done in the scripts.

## Adding a new PostgreSQL version to the repository

* Update apt.postgresql.org/repo/conf/distributions.sh and re-generate the distributions file
* Update `PG_DEVEL_VERSION` in pgapt.conf
* Possibly update the Jenkins pipeline jobs to include the new version
* Update the repository master host: cd /srv/apt; sudo -u aptuser git pull
* Create new Jenkins jobs and build them

## Changing the default PostgreSQL version

* Update `PG_MAIN_VERSION` in pgapt.conf
* Update the repository master host: cd /srv/apt; sudo -u aptuser git pull
* Rebuild the old default version so its libpq gets added to the extra component (as it was in main before)
* Rebuild the new default version so its libpq gets added to main (as it was in the extra component before)
* Possibly update the Jenkins pipeline jobs to stop triggering beta jobs
* In postgresql-common, update debian/supported-versions
* To remove obsolete old lib packages, use
  ```
  . /srv/apt/pgapt.conf
  COMPONENT=11
  PKGS="libpq5 libecpg6 libecpg-compat3 libecpg-dev libpgtypes3 libpq-dev"
  for dist in $PG_SUPPORTED_DISTS; do for pkg in $PKGS; do sudo -u aptuser reprepro -C $COMPONENT remove $dist-pgdg-testing $pkg $pkg-dbgsym; done; done
  ```
* Removing obsolete PG component:
  ```
  . /srv/apt/pgapt.conf
  COMPONENT=11
  PKGS="libecpg6 libecpg-compat3 libecpg-dev libpgtypes3 libpq5 libpq-dev postgresql-$COMPONENT postgresql-$COMPONENT-dbg postgresql-client-$COMPONENT postgresql-contrib-$COMPONENT postgresql-doc-$COMPONENT postgresql-plperl-$COMPONENT postgresql-plpython3-$COMPONENT postgresql-plpython-$COMPONENT postgresql-pltcl-$COMPONENT postgresql-server-dev-$COMPONENT"
  for dist in $PG_SUPPORTED_DISTS; do for pkg in $PKGS; do sudo -u aptuser reprepro -C $COMPONENT remove $dist-pgdg-testing $pkg $pkg-dbgsym; done; done
  ```

## Changing the set of supported PostgreSQL versions

* In postgresql-common, update debian/supported-versions
* Trigger a postgresql-common build
* Upgrade postgresql-common on pgdgbuild.dus.dg-i.net because
  generate-pgdg-source uses the list when generating debian/control from
  debian/control.in
* Restrict deprecated version to `dist-filter: '(distribution=="sid")'`
* Announce change on wiki and the mailing list

## Adding a new distribution

Update these files in git:

* pgapt.conf
* repo/conf/distributions.sh and generate repo/conf/distributions from it
* repo/conf/incoming
* jenkins/pgapt-jobs.yaml

Update repository master host:

* cd /srv/apt; sudo -u aptuser git pull
* Seed initial packages:
  * reprepro copysrc $newdist-pgdg-testing $olddist-pgdg-testing postgresql-common pgdg-keyring pgdg-buildenv postgresql-x.y
  * make sure to copy from a distribution that has all the target architectures (even if the package is arch:all, #926233)
* possibly: reprepro copymatched $newdist-pgdg $newdist-pgdg-testing \*
* or: reprepro export $newdist-pgdg (so apt can run update on it even if it's still empty)
* Wait until the mirror sync has run (xx:17)

Update Jenkins hosts:

* Run the "apt.postgresql.org" job
* cd jenkins/ansible; ./setup-buildd.yml
* Run the "sbuild-update" job

Do the paperwork:

* Update wiki pages
* Update pgdg/apt.postgresql.org.sh in postgresql-common
* Send announcement

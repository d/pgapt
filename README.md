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

## Adding a new distribution

Update these files:

* pgapt.conf
* repo/conf/distributions.sh and generate repo/conf/distributions from it
* repo/conf/incoming
* jenkins/pgapt-jobs.yaml

Update repository master host:

* cd /srv/apt/apt.postgresql.org; git pull
* Seed initial packages: reprepro copysrc $newdist-pgdg-testing $olddist-pgdg-testing postgresql-common pgdg-keyring pgdg-buildenv; postgresql-x.y from sid-pgdg-testing (or whatever seems appropriate)
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

# apt.postgresql.org

The main idea of this project is to provide PostgreSQL and its Extensions
packages for all supported PostgreSQL versions and debian version. That
means things like PostgreSQL 9.1 for `squeeze`, with all known debian
extensions, and for `sid` and `wheezy` too. And same for `8.3` and `8.4` and
`9.0` and `9.1` and `9.2`. Targeting `i386` and `amd64`.

https://wiki.postgresql.org/wiki/Apt

## Build System

The build system is currently based on jenkins and some scripting. `Jenkins`
is only about lauching the build jobs, the real work is done in the scripts.

## Sources

Either `bzr` or `git` or `svn`, or `apt-get source`.

A Note on Components
====================

Almost all packages in the apt.postgresql.org repository, including the
PostgreSQL server packages for all versions, are located in the "main"
component (aka directory). The other N.N components here (like "9.2") merely
serve as stowage for the non-default-version library packages built from server
packages. The libpq packages from the older PostgreSQL versions live here, as
well as those from beta and devel branches. The libpq packages from the newest
stable PostgreSQL version live in "main" as well.

This is why the N.N directories here only contain few package, and most of the
time there will not even be a directory for the "current" stable PostgreSQL
version.

To use the repository, follow the instructions at

	https://wiki.postgresql.org/wiki/Apt

People using the apt.postgresql.org repository should usually only be concerned
about using the "main" component, unless installing beta or devel versions of
the PostgreSQL server packages:

	https://wiki.postgresql.org/wiki/Apt/FAQ#I_want_to_try_the_beta_version_of_the_next_PostgreSQL_release

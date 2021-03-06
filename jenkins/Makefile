JOBS = pgapt-jobs.yaml
JJB = jenkins-jobs

all: test lists

# we write to output.tmp first so output.{old,new} are left untouched in case
# JJB aborts
test:
	@echo "*** Testing $(JOBS) ***"
	rm -rf output.tmp
	mkdir output.tmp
	$(JJB) test --config-xml -o output.tmp $(JOBS)
	if test -d output.new; then rm -rf output.old; mv output.new output.old; fi
	mv output.tmp output.new
	test -d output.old && diff -urp output.old output.new || true

update:
	@echo "*** Updating Jenkins from $(JOBS) ***"
	$(JJB) update $(JOBS)

update-pgdgbuild:
	@echo "*** Updating Jenkins from $(JOBS) ***"
	$(JJB) --conf jenkins_jobs.ini update $(JOBS)

# package lists
lists: packages packages.modules packages.backports packages.backports_runtime
packages: pgapt-jobs.yaml
	perl -wle 'use YAML::Syck; $$y = LoadFile("pgapt-jobs.yaml"); foreach $$p (@$$y) { print $$p->{project}->{name} if $$p->{project}->{name} }' | grep -v '^upgrade-' | sort > $@
packages.modules: pgapt-jobs.yaml # packages that build PG modules for "beta"
	perl -wle 'use YAML::Syck; $$y = LoadFile("pgapt-jobs.yaml"); foreach $$p (@$$y) { print $$p->{project}->{name} if $$p->{project}->{name} and $$p->{project}->{jobs}->[0] eq "git-packages-with-beta" }' | sort > $@
packages.%: pgapt-jobs.yaml
	perl -wle 'use YAML::Syck; $$y = LoadFile("pgapt-jobs.yaml"); foreach $$p (@$$y) { print $$p->{project}->{name} if $$p->{project}->{$*} or $$p->{project}->{"<<"}->{$*} }' | sort > $@

clean:
	rm -rf output output.old packages.backports*

# install scripts
SCRIPTS = adt-sbuild adtsummary2junit approx-reset.sh builddebcheck-pgapt debcheck-pgapt dput-pgdg generate-pgdg-source newpid-netns pgdg-autopkgtest postgresql-testsuite sbuild-package sbuild-update.sh
INST_SCRIPTS = $(patsubst %, /usr/local/bin/%, $(SCRIPTS))

install: $(INST_SCRIPTS)

/usr/local/bin/%: %
	install $< $@

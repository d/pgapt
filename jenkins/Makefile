JOBS = pgapt-jobs.yaml
JJB = jenkins-jobs

all: test lists

# we write to output.tmp first so output.{old,new} are left untouched in case
# JJB aborts
test:
	@echo "*** Testing $(JOBS) ***"
	rm -rf output.tmp
	mkdir output.tmp
	$(JJB) test -o output.tmp $(JOBS)
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
lists: packages.backports
packages.backports: pgapt-jobs.yaml
	perl -le 'use YAML::Syck; $$y = LoadFile("pgapt-jobs.yaml"); foreach $$p (@$$y) { print $$p->{project}->{name} if $$p->{project}->{backports} or $$p->{project}->{"<<"}->{backports} }' > $@

clean:
	rm -rf output output.old packages.backports

# install scripts
SCRIPTS = adt-sbuild adtsummary2junit approx-reset.sh builddebcheck-pgapt debcheck-pgapt dput-pgdg generate-pgdg-source newpid-netns postgresql-testsuite sbuild-package sbuild-update.sh
INST_SCRIPTS = $(patsubst %, /usr/local/bin/%, $(SCRIPTS))

install: $(INST_SCRIPTS)

/usr/local/bin/%: %
	install $< $@

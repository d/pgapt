JOBS = pgapt-jobs.yaml

# we write to output.tmp first so output.{old,new} are left untouched in case
# jenkins-jobs aborts
test:
	@echo "*** Testing $(JOBS) ***"
	rm -rf output.tmp
	mkdir output.tmp
	jenkins-jobs test -o output.tmp $(JOBS)
	if test -d output.new; then rm -rf output.old; mv output.new output.old; fi
	mv output.tmp output.new
	test -d output.old && diff -urp output.old output.new || true

update:
	@echo "*** Updating Jenkins from $(JOBS) ***"
	jenkins-jobs update $(JOBS)

update-pgdgbuild:
	@echo "*** Updating Jenkins from $(JOBS) ***"
	jenkins-jobs --conf jenkins_jobs.ini update $(JOBS)

clean:
	rm -rf output output.old

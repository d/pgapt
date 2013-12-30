# we write to output.tmp first so output.{old,new} are left untouched in case
# jenkins-jobs aborts
test:
	@echo "*** Testing pgapt-jobs.yaml ***"
	rm -rf output.tmp
	mkdir output.tmp
	jenkins-jobs test -o output.tmp pgapt-jobs.yaml
	if test -d output.new; then rm -rf output.old; mv output.new output.old; fi
	mv output.tmp output.new
	test -d output.old && diff -urp output.old output.new || true

update:
	@echo "*** Updating Jenkins from pgapt-jobs.yaml ***"
	jenkins-jobs update pgapt-jobs.yaml

clean:
	rm -rf output output.old

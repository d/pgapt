test:
	rm -rf output.old
	test -d output && mv output output.old
	mkdir output
	jenkins-jobs test -o output pgapt-jobs.yaml
	test -d output.old && diff -urp output.old output || true

update:
	jenkins-jobs update pgapt-jobs.yaml

clean:
	rm -rf output output.old

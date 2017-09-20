apt.postgresql.org build setup
==============================

Jenkins
-------

Jenkins jobs are created from pgapt-jobs.yaml. To test changes, install
`jenkins-job-builder` and run "make" before and after doing the change, it will
show the diff between the generated jenkins config. (Does not need jenkins
running locally.)

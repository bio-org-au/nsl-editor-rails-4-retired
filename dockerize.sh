#! /bin/bash
docker build -t nsl-editor .
docker tag nsl-editor pmcneil/nsl-editor:1.88-SNAP
docker push pmcneil/nsl-editor:1.88-SNAP
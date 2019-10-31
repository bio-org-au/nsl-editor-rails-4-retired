#! /bin/bash
docker build -t nsl-editor .
docker tag nsl-editor biodiversity/nsl-editor:1.88-SNAP
docker push biodiversity/nsl-editor:1.88-SNAP
#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <project>"
  exit 1
fi

oc get project "$1" -o yaml \
	| yq d - metadata.annotations \
	| yq d - metadata.creationTimestamp \
	| yq d - metadata.labels \
	| yq d - metadata.resourceVersion \
	| yq d - metadata.uid \
    | yq d - spec \
	| yq d - status \
    | sed -ie 's/Project/ProjectRequest/g'


#!/usr/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <route>"
  exit 1
fi

oc get route "$1" -o yaml \
	| yq d - metadata.annotations \
	| yq d - metadata.creationTimestamp \
	| yq d - metadata.namespace \
	| yq d - metadata.resourceVersion \
	| yq d - metadata.uid \
	| yq d - spec.host \
	| yq d - status


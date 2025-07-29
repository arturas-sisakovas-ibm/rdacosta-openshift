#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <pvc_name>"
  exit 1
fi

oc get pvc "$1" -o yaml \
	| yq d - metadata.annotations \
	| yq d - metadata.creationTimestamp \
	| yq d - metadata.finalizers \
	| yq d - metadata.namespace \
	| yq d - metadata.resourceVersion \
	| yq d - metadata.uid \
	| yq d - spec.volumeName \
	| yq d - status


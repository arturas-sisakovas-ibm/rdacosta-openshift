#!/usr/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <virtualmachine>"
  exit 1
fi

oc get vm "$1" -o yaml \
	| yq d - metadata.annotations \
	| yq d - metadata.creationTimestamp \
	| yq d - metadata.finalizers \
	| yq d - metadata.generation \
	| yq d - metadata.namespace \
	| yq d - metadata.resourceVersion \
	| yq d - metadata.uid \
	| yq d - spec.instancetype.revisionName \
	| yq d - spec.preference.revisionName \
	| yq d - status \
	| sed 's/\(macAddress:\).*/\1 "52:54:00:00:00:00"/' 

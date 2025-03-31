#!/usr/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <netpol_name>"
  exit 1
fi

oc get netpol "$1" -o yaml \
	| yq d - metadata.annotations \
	| yq d - metadata.creationTimestamp \
	| yq d - metadata.namespace \
	| yq d - metadata.resourceVersion \
	| yq d - metadata.uid \
	| yq d - metadata.generation \
	| yq d - spec.clusterIP* \
	| yq d - status


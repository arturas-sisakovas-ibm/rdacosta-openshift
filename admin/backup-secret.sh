/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <secret_name>"
  exit 1
fi

oc get secret "$1" -o yaml \
	| yq d - metadata.annotations \
	| yq d - metadata.creationTimestamp \
	| yq d - metadata.namespace \
	| yq d - metadata.resourceVersion \
	| yq d - metadata.uid \
	| yq d - status


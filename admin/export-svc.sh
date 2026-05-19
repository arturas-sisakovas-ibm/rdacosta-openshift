#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <service_name>" >&2
  exit 1
fi

oc get svc "$1" -o yaml \
  | yq 'del(.metadata.managedFields,
            .metadata.ownerReferences,
            .metadata.creationTimestamp,
            .metadata.deletionTimestamp,
            .metadata.deletionGracePeriodSeconds,
            .metadata.resourceVersion,
            .metadata.uid,
            .spec.clusterIP,
            .spec.clusterIPs,
            .status)
        | del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
              .metadata.annotations."openshift.io/generated-by")'

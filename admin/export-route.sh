#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <route_name>" >&2
  exit 1
fi

oc get route "$1" -o yaml \
  | yq 'del(.metadata.managedFields,
            .metadata.ownerReferences,
            .metadata.creationTimestamp,
            .metadata.deletionTimestamp,
            .metadata.deletionGracePeriodSeconds,
            .metadata.resourceVersion,
            .metadata.uid,
            .spec.host,
            .status)
        | del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
              .metadata.annotations."openshift.io/host.generated",
              .metadata.annotations."openshift.io/generated-by")'

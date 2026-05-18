#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <deployment_name>" >&2
  exit 1
fi

oc get deploy "$1" -o yaml \
  | yq 'del(.metadata.managedFields,
            .metadata.ownerReferences,
            .metadata.creationTimestamp,
            .metadata.deletionTimestamp,
            .metadata.deletionGracePeriodSeconds,
            .metadata.resourceVersion,
            .metadata.uid,
            .metadata.generation,
            .status)
        | del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
              .metadata.annotations."deployment.kubernetes.io/revision",
              .spec.template.metadata.annotations."kubectl.kubernetes.io/restartedAt",
              .spec.template.metadata.annotations."openshift.io/generated-by")' \
  | sed 's/@sha.*/:latest/g'

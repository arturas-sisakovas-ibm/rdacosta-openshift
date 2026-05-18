#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <virtualmachine_name>" >&2
  exit 1
fi

oc get vm "$1" -o yaml \
  | yq 'del(.metadata.managedFields,
            .metadata.ownerReferences,
            .metadata.creationTimestamp,
            .metadata.deletionTimestamp,
            .metadata.deletionGracePeriodSeconds,
            .metadata.resourceVersion,
            .metadata.uid,
            .metadata.generation,
            .metadata.finalizers,
            .spec.instancetype.revisionName,
            .spec.preference.revisionName,
            .status)
        | del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
              .metadata.annotations."kubevirt.io/latest-observed-api-version",
              .metadata.annotations."kubevirt.io/storage-observed-api-version")' \
  | sed 's/\(macAddress:\).*/\1 "52:54:00:00:00:00"/'

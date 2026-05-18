#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <pvc_name>" >&2
  exit 1
fi

oc get pvc "$1" -o yaml \
  | yq 'del(.metadata.managedFields,
            .metadata.ownerReferences,
            .metadata.creationTimestamp,
            .metadata.deletionTimestamp,
            .metadata.deletionGracePeriodSeconds,
            .metadata.resourceVersion,
            .metadata.uid,
            .metadata.finalizers,
            .spec.volumeName,
            .status)
        | del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
              .metadata.annotations."pv.kubernetes.io/bind-completed",
              .metadata.annotations."pv.kubernetes.io/bound-by-controller",
              .metadata.annotations."volume.beta.kubernetes.io/storage-provisioner",
              .metadata.annotations."volume.kubernetes.io/storage-provisioner")'

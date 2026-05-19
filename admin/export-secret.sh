#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <secret_name>" >&2
  exit 1
fi

echo "# WARNING: Secret data will be exported in base64-encoded format" >&2
echo "# DO NOT commit to Git or share outside training environment" >&2
echo "# Decode with: echo '<value>' | base64 -d" >&2
echo "" >&2

oc get secret "$1" -o yaml \
  | yq 'del(.metadata.managedFields,
            .metadata.ownerReferences,
            .metadata.creationTimestamp,
            .metadata.deletionTimestamp,
            .metadata.deletionGracePeriodSeconds,
            .metadata.resourceVersion,
            .metadata.uid,
            .status)
        | del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
              .metadata.annotations."pv.kubernetes.io/bind-completed",
              .metadata.annotations."pv.kubernetes.io/bound-by-controller",
              .metadata.annotations."volume.beta.kubernetes.io/storage-provisioner",
              .metadata.annotations."openshift.io/sa.scc.mcs",
              .metadata.annotations."openshift.io/sa.scc.supplemental-groups",
              .metadata.annotations."openshift.io/sa.scc.uid-range",
              .metadata.annotations."openshift.io/generated-by")'

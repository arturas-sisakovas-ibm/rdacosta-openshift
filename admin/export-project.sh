#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <project_name>" >&2
  exit 1
fi

oc get project "$1" -o yaml \
  | yq 'del(.metadata.managedFields,
            .metadata.ownerReferences,
            .metadata.creationTimestamp,
            .metadata.deletionTimestamp,
            .metadata.deletionGracePeriodSeconds,
            .metadata.resourceVersion,
            .metadata.uid,
            .spec,
            .status)
        | del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
              .metadata.annotations."openshift.io/sa.scc.mcs",
              .metadata.annotations."openshift.io/sa.scc.supplemental-groups",
              .metadata.annotations."openshift.io/sa.scc.uid-range")
        | del(.metadata.labels."kubernetes.io/metadata.name",
              .metadata.labels."pod-security.kubernetes.io/audit",
              .metadata.labels."pod-security.kubernetes.io/warn",
              .metadata.labels."pod-security.kubernetes.io/enforce")' \
  | sed 's/kind: Project$/kind: ProjectRequest/'

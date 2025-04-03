#!/bin/bash

BACKUP_NAME="$1"
BUCKET_NAME="$(oc get backupstoragelocation/oadp-dpa-1 -n openshift-adp -o yaml | yq r - spec.objectStorage.bucket)"

step_break() {
  echo
  echo "-----------------------------------------------------"
  echo "$1"
  echo "-----------------------------------------------------"
	}

if [[ -z "$BACKUP_NAME" || -z "$BUCKET_NAME" ]]; then
	  echo "Usage: $0 <backup-name> <bucket-name>"
	    exit 1
fi

step_break "Deleting backup: $BACKUP_NAME from bucket: $BUCKET_NAME"

step_break "Step 1: Deleting VolumeSnapshots..."
oc delete volumesnapshots -A -l velero.io/backup-name="$BACKUP_NAME"

step_break "Step 2: Deleting VolumeSnapshotContents..."
oc delete volumesnapshotcontents -l velero.io/backup-name="$BACKUP_NAME"

step_break "Step 3: Deleting PodVolumeBackups..."
oc delete podvolumebackups -A -l velero.io/backup-name="$BACKUP_NAME"

step_break "Step 4: Deleting Restores (if any)..."
oc delete restores -n openshift-adp -l velero.io/backup-name="$BACKUP_NAME"

step_break "Step 5: Deleting Velero Backup..."
oc delete backup -n openshift-adp "$BACKUP_NAME"

step_break "Step 6: Deleting from Object Store (s3cmd)..."
OBJECT_PATH="s3://${BUCKET_NAME}/velero/backups/${BACKUP_NAME}/"
s3cmd del --recursive "$OBJECT_PATH"

step_break "✅ Backup deletion complete."


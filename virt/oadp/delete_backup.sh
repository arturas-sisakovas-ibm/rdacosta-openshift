#!/bin/bash

BACKUP_NAME="$1"

BUCKET_NAME=$(oc get backupstoragelocation oadp-backup-1 \
  -n openshift-adp \
  -o jsonpath='{.spec.objectStorage.bucket}')

step_break() {
  echo
  echo "-----------------------------------------------------"
  echo "🔧 $1"
  echo "-----------------------------------------------------"
}

if [[ -z "$BACKUP_NAME" ]]; then
  echo "Usage: $0 <backup-name>"
  exit 1
fi

if [[ -z "$BUCKET_NAME" ]]; then
  echo "❌ Could not determine bucket name from BackupStorageLocation."
  exit 1
fi

OBJECT_PATH="s3://${BUCKET_NAME}/oadp/backups/${BACKUP_NAME}/"

step_break "Deleting backup: $BACKUP_NAME from bucket: $BUCKET_NAME"

step_break "Step 1: Deleting VolumeSnapshots..."
oc delete volumesnapshots -A -l velero.io/backup-name="$BACKUP_NAME" --ignore-not-found

step_break "Step 2: Deleting VolumeSnapshotContents..."
oc delete volumesnapshotcontents -l velero.io/backup-name="$BACKUP_NAME" --ignore-not-found

step_break "Step 3: Deleting PodVolumeBackups..."
oc delete podvolumebackups -A -l velero.io/backup-name="$BACKUP_NAME" --ignore-not-found

step_break "Step 4: Deleting Restores (if any)..."
oc delete restores -n openshift-adp -l velero.io/backup-name="$BACKUP_NAME" --ignore-not-found

step_break "Step 5: Deleting Velero Backup..."
oc delete backup -n openshift-adp "$BACKUP_NAME" --ignore-not-found

step_break "Step 6: Deleting from Object Store (AWS CLI)..."
aws s3 rm "$OBJECT_PATH" --recursive --endpoint-url https://s3-openshift-storage.apps.ocp4.example.com --no-verify-ssl

step_break "✅ Backup deletion complete."

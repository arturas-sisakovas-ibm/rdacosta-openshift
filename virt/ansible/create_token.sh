#!/bin/bash
set -euo pipefail

SA_NAME="aap"
NAMESPACE="default"
TOKEN_FILE="aap_token"

echo "🔗 Checking OpenShift connection..."
oc whoami >/dev/null 2>&1 || { echo "Not logged in to OpenShift."; exit 1; }

echo "🤖 Ensuring ServiceAccount '$SA_NAME' exists..."
if ! oc get sa "$SA_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
    oc create sa "$SA_NAME" -n "$NAMESPACE"
fi

echo "🎫 Generating token (valid for 1 year)..."
TOKEN=$(oc create token "$SA_NAME" -n "$NAMESPACE" --duration=8760h) || {
    echo "Failed to generate token"
    exit 1
}

umask 077
echo "$TOKEN" > "$TOKEN_FILE"

echo "🫡 Applying cluster role binding ..."
oc adm policy add-cluster-role-to-user edit -z "$SA_NAME" -n "$NAMESPACE" >/dev/null 2>&1 || true

echo "✅ Done."
echo "🎫 Token written to: $TOKEN_FILE"

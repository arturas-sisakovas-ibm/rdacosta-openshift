#!/bin/bash

# Set default values
MY_PREFIX="backup"
MY_USER="rgdacosta"
MY_API="https://api.ocp4.example.com:6443"

# Override defaults with command-line arguments if provided
if [[ $# -gt 0 ]]; then
  MY_USER=$1
fi

if [[ $# -gt 1 ]]; then
  MY_API=$2
fi

MY_BACKUP="${MY_PREFIX}-${MY_USER}"
MY_KUBECONFIG="${MY_BACKUP}-kubeconfig"

# Create directory and navigate to it
mkdir -pv "${HOME}/my_certs"
cd "${HOME}/my_certs"

# Add cluster-admin role to the user
oc adm policy add-cluster-role-to-user cluster-admin "${MY_BACKUP}"

# Generate key and CSR
openssl req -newkey rsa:4096 -nodes -keyout "${MY_BACKUP}.tls" -subj "/CN=${MY_BACKUP}" -out "${MY_BACKUP}.csr"

# Encode CSR
ENCODED_CSR=$(base64 -w0 "${MY_BACKUP}.csr" | tr -d '\n')

# Create CSR YAML
cat <<EOF >> "${MY_BACKUP}-csr.yaml"
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: "${MY_BACKUP}"
spec:
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 604800
  request: "${ENCODED_CSR}"
  usages:
  - client auth
EOF

# Apply CSR and approve certificate
oc apply -f "${MY_BACKUP}-csr.yaml"
oc adm certificate approve "${MY_BACKUP}"

# Extract certificate
oc get -o json csr "${MY_BACKUP}" | jq -r '.status.certificate' | base64 -d > "${MY_BACKUP}.crt"

# Configure kubeconfig
oc config set-credentials "${MY_BACKUP}" \
  --client-certificate="${MY_BACKUP}.crt" \
  --client-key="${MY_BACKUP}.tls" \
  --embed-certs \
  --kubeconfig="${MY_KUBECONFIG}"

# Extract API server certificate
openssl s_client -showcerts -connect "${MY_API#https://}" </dev/null 2>/dev/null | \
  openssl x509 -outform PEM > "$(echo "${MY_API//./-}" | cut -d '/' -f 3).crt"

# Configure cluster in kubeconfig
oc config set-cluster "$(echo "${MY_API//./-}" | cut -d '/' -f 3)" \
  --certificate-authority="$(echo "${MY_API//./-}" | cut -d '/' -f 3).crt" \
  --embed-certs=true \
  --server="${MY_API}" \
  --kubeconfig="${MY_KUBECONFIG}"

# Configure context in kubeconfig
oc config set-context "${MY_BACKUP}" \
  --cluster="$(echo "${MY_API//./-}" | cut -d '/' -f 3)" \
  --namespace="default" \
  --user="${MY_BACKUP}" \
  --kubeconfig="${MY_KUBECONFIG}"

# Set current context
oc config use-context "${MY_BACKUP}" --kubeconfig="${MY_KUBECONFIG}"

/!/bin/bash

# Set default values
MY_PREFIX="cert"
MY_USER="rgdacosta"
MY_API="https://api.ocp4.example.com:6443"

# Override defaults with command-line arguments if provided
if [[ $# -gt 0 ]]; then
  MY_USER=$1
fi

if [[ $# -gt 1 ]]; then
  MY_API=$2
fi

MY_ADMIN="${MY_PREFIX}-${MY_USER}"
MY_KUBECONFIG="${MY_ADMIN}-kubeconfig"

# Create directory and navigate to it
mkdir -pv "${HOME}/my_certs"
cd "${HOME}/my_certs"

# Add cluster-admin role to the user
oc adm policy add-cluster-role-to-user cluster-admin "${MY_ADMIN}"

# Generate key and CSR
openssl req -newkey rsa:4096 -nodes -keyout "${MY_ADMIN}.tls" -subj "/CN=${MY_ADMIN}" -out "${MY_ADMIN}.csr"

# Encode CSR
ENCODED_CSR=$(base64 -w0 "${MY_ADMIN}.csr" | tr -d '\n')

# Create CSR YAML
cat <<EOF >> "${MY_ADMIN}-csr.yaml"
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: "${MY_ADMIN}"
spec:
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 604800
  request: "${ENCODED_CSR}"
  usages:
  - client auth
EOF

# Apply CSR and approve certificate
oc apply -f "${MY_ADMIN}-csr.yaml"
oc adm certificate approve "${MY_ADMIN}"

# Extract certificate
oc get -o json csr "${MY_ADMIN}" | jq -r '.status.certificate' | base64 -d > "${MY_ADMIN}.crt"

# Configure kubeconfig
oc config set-credentials "${MY_ADMIN}" \
  --client-certificate="${MY_ADMIN}.crt" \
  --client-key="${MY_ADMIN}.tls" \
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
oc config set-context "${MY_ADMIN}" \
  --cluster="$(echo "${MY_API//./-}" | cut -d '/' -f 3)" \
  --namespace="default" \
  --user="${MY_ADMIN}" \
  --kubeconfig="${MY_KUBECONFIG}"

# Set current context
oc config use-context "${MY_ADMIN}" --kubeconfig="${MY_KUBECONFIG}"

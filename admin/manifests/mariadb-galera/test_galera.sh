#!/bin/bash

set -euo pipefail

NAMESPACE=$(oc config view --minify --output 'jsonpath={..namespace}')
NAMESPACE=${NAMESPACE:-default}
STATEFULSET="mariadb-galera"
PASSWORD="redhat123"

oc get pods -n "$NAMESPACE"
oc wait --for=condition=Ready pod -l app=$STATEFULSET -n "$NAMESPACE" --timeout=180s

PODS=$(oc get pods -l app=$STATEFULSET -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
FIRST_POD=$(echo $PODS | awk '{print $1}')
SECOND_POD=$(echo $PODS | awk '{print $2}')

oc exec -n "$NAMESPACE" "$FIRST_POD" -- /opt/bitnami/mariadb/bin/mariadb -uroot -p"$PASSWORD" -e "
SHOW STATUS LIKE 'wsrep_cluster_size';
SHOW STATUS LIKE 'wsrep_cluster_status';
"

oc exec -n "$NAMESPACE" "$FIRST_POD" -- /opt/bitnami/mariadb/bin/mariadb -uroot -p"$PASSWORD" -e "
CREATE DATABASE IF NOT EXISTS galeratest;
USE galeratest;
CREATE TABLE IF NOT EXISTS hello (id INT PRIMARY KEY, message VARCHAR(255));
INSERT INTO hello (id, message) VALUES (1, 'Hello from cluster!');
SELECT * FROM hello;
"

oc exec -n "$NAMESPACE" "$SECOND_POD" -- /opt/bitnami/mariadb/bin/mariadb -uroot -p"$PASSWORD" -e "
USE galeratest;
SELECT * FROM hello;
"

oc delete pod "$SECOND_POD" -n "$NAMESPACE"
oc wait --for=condition=Ready pod/"$SECOND_POD" -n "$NAMESPACE" --timeout=180s

oc exec -n "$NAMESPACE" "$FIRST_POD" -- /opt/bitnami/mariadb/bin/mariadb -uroot -p"$PASSWORD" -e "
SHOW STATUS LIKE 'wsrep_cluster_size';
"

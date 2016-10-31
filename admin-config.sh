#!/bin/bash


print-usage() {
    echo "Usage: $0 <master_host> <keys_root>"
    exit 1
}

MASTER_HOST=$1
CERTS=$2

CA_CERT=$CERTS/ca.pem

ADMINDIR=$CERTS/admin
ADMIN_KEY=$ADMINDIR/admin-key.pem
ADMIN_CERT=$ADMINDIR/admin.pem

admin-config() {
    kubectl config set-cluster default-cluster --server=https://${MASTER_HOST} --certificate-authority=${CA_CERT}
    kubectl config set-credentials default-admin --certificate-authority=${CA_CERT} --client-key=${ADMIN_KEY} --client-certificate=${ADMIN_CERT}
    kubectl config set-context default-system --cluster=default-cluster --user=default-admin
    kubectl config use-context default-system
}

admin-config

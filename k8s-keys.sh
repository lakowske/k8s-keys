#!/bin/bash
#
# Generates a set of keys and stream to stdout in tar format
#
# Seth Lakowske
# Copyright 2016
# License: BSD3
#
# Example:
# ./k8s-keys.sh all worker0 192.168.10.100 | tar -xf -


print-usage() {
    echo "Usage: $0 <api <node_fqdn> <node_ip> [external_ip]|
                     admin|
                     ca|
                     worker <node_fqdn> <node_ip>>|
                     all <node_fqdn> <node_ip>>"
    exit 1
}

CMD=$1
NODE_FQDN=$2
NODE_IP=$3
EXTERNAL_IP=$4

MASTER_HOST=$2

CERTS=/certs

ADMINDIR=$CERTS/admin
WORKERDIR=$CERTS/workers/$WORKER_FQDN
CA=$CERTS/ca.pem
CA_KEY=$CERTS/ca-key.pem
OPENSSL_CONF=$CERTS/openssl.cnf

admin-keys() {
    CSR=$ADMINDIR/admin.csr

    mkdir -p $ADMINDIR

    /usr/bin/openssl  genrsa -out $ADMINDIR/admin-key.pem 2048

    /usr/bin/openssl req -new -key $ADMINDIR/admin-key.pem -out $CSR -subj "/CN=kube-admin"

    /usr/bin/openssl x509 -req -in $CSR -CA $CA -CAkey $CA_KEY -CAcreateserial -out $ADMINDIR/admin.pem -days 1000

    rm $CSR

}

node-keys() {
    CA_KEY=$CERTS/ca-key.pem
    NODEDIR=$CERTS/nodes/$1
    KEYDIR=$NODEDIR/etc/kubernetes/ssl
    CSR=$KEYDIR/node.csr

    KEYTYPE=$2
    SUBJ=$3

    mkdir -p $KEYDIR

    /usr/bin/openssl genrsa -out $KEYDIR/$KEYTYPE-key.pem 2048

    /usr/bin/openssl req -new -key $KEYDIR/$KEYTYPE-key.pem -out $CSR -subj "$SUBJ" -config $OPENSSL_CONF

    /usr/bin/openssl x509 -req -in $CSR -CA $CA -CAkey $CA_KEY -CAcreateserial -out $KEYDIR/$KEYTYPE.pem -days 1000 -extensions v3_req -extfile $OPENSSL_CONF

    cp $CA $KEYDIR

    rm $CSR
}

worker-keys() {
    export NODE_IP=$NODE_IP
    export EXTERNAL_IP=$EXTERNAL_IP
    CSR=$WORKERDIR/$NODE_FQDN-worker.csr

    node-keys $NODE_FQDN worker "/CN=$NODE_FQDN"
}


api-keys() {
    CSR=$CERTS/apiserver.csr
    node-keys $NODE_FQDN apiserver "/CN=kube-apiserver"
}

#Create our own CA (Certificate Authority)
ca() {
    #Generates a RSA keypair.
    #  Public key can be extracted: openssl rsa -in $CA_KEY -pubout
    #  Verify key consistency with: openssl rsa -in $CA_KEY -check
    /usr/bin/openssl genrsa -out $CA_KEY 2048

    #Generates self-signed certificate and writes it to $CA
    /usr/bin/openssl req -x509 -new -nodes -key $CA_KEY -days 10000 -out $CA -subj "/CN=kube-ca"
}

parse-cmd() {

    (cd /certs ; tar -xf - .)

    case $CMD in
        admin)
            admin-keys
            ;;
        worker)
            worker-keys
            ;;
        api)
            api-keys
            ;;
        ca)
            ca
            ;;
        all)
            ca
            api-keys
            admin-keys
            ;;
        *)
            print-usage
            ;;
    esac

    (cd /certs ; tar -cf - .)
}

parse-cmd

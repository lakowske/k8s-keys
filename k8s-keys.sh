#!/bin/bash

print-usage() {
    echo "Usage: $0 <api|
                     admin|
                     worker <worker_fqdn> <worker_ip>>|
                     all <worker_fqdn> <worker_ip>>"
    exit 1
}

CMD=$1
WORKER_FQDN=$2
WORKER_IP=$3

MASTER_HOST=$2

CERTS=/certs
APIKEYDIR=$CERTS/etc/kubernetes/ssl

ADMINDIR=$CERTS/admin
WORKERDIR=$CERTS/workers/$WORKER_FQDN

worker-keys() {
    echo "worker: $WORKER_FQDN $WORKER_IP"
    #Need to set env variable for use in worker-openssl.cnf
    export WORKER_IP=$WORKER_IP
    CSR=$WORKERDIR/$WORKER_FQDN-worker.csr

    mkdir -p $WORKERDIR

    /usr/bin/openssl  genrsa -out $WORKERDIR/$WORKER_FQDN-worker-key.pem 2048

    #requires /worker-openssl.cnf
    /usr/bin/openssl req -new -key $WORKERDIR/$WORKER_FQDN-worker-key.pem -out $CSR -subj "/CN=$WORKER_FQDN" -config /worker-openssl.cnf

    /usr/bin/openssl x509 -req -in $CSR -CA $APIKEYDIR/ca.pem -CAkey $CERTS/ca-key.pem -CAcreateserial -out $WORKERDIR/$WORKER_FQDN-worker.pem -days 365 -extensions v3_req -extfile /worker-openssl.cnf

    rm $CSR
}

admin-keys() {
    CSR=$ADMINDIR/admin.csr

    mkdir -p $ADMINDIR
    /usr/bin/openssl  genrsa -out $ADMINDIR/admin-key.pem 2048

    /usr/bin/openssl req -new -key $ADMINDIR/admin-key.pem -out $CSR -subj "/CN=kube-admin"

    /usr/bin/openssl x509 -req -in $CSR -CA $APIKEYDIR/ca.pem -CAkey $CERTS/ca-key.pem -CAcreateserial -out $ADMINDIR/admin.pem -days 365

    rm $CSR
}


api-keys() {

    CA_KEY=$CERTS/ca-key.pem
    CSR=$CERTS/apiserver.csr

    mkdir -p $APIKEYDIR

    /usr/bin/openssl genrsa -out $CA_KEY 2048

    /usr/bin/openssl req -x509 -new -nodes -key $CA_KEY -days 10000 -out $APIKEYDIR/ca.pem -subj "/CN=kube-ca"

    /usr/bin/openssl genrsa -out $APIKEYDIR/apiserver-key.pem 2048

    /usr/bin/openssl req -new -key $APIKEYDIR/apiserver-key.pem -out $CSR -subj "/CN=kube-apiserver" -config /openssl.cnf

    /usr/bin/openssl x509 -req -in $CSR -CA $APIKEYDIR/ca.pem -CAkey $CA_KEY -CAcreateserial -out $APIKEYDIR/apiserver.pem -days 365 -extensions v3_req -extfile /openssl.cnf

    rm $CSR
}

parse-cmd() {
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
        all)
            api-keys
            admin-keys
            worker-keys
            ;;
        *)
            print-usage
            ;;
    esac
}

parse-cmd

#!/bin/bash

print-usage() {
    echo "Usage: $0 <api|admin|worker <worker_fqdn> <worker_ip>>"
    exit 1
}

CMD=$1
WORKER_FQDN=$2
WORKER_IP=$3


CERTS=/certs
APIKEYDIR=$CERTS/etc/kubernetes/ssl

worker-keys() {
    echo "worker: $WORKER_FQDN $WORKER_IP"
    export WORKER_IP=$WORKER_IP

    KEYDIR=$CERTS/$WORKER_FQDN

    mkdir -p $KEYDIR
    /usr/bin/openssl  genrsa -out $KEYDIR/$WORKER_FQDN-worker-key.pem 2048

    #requires /worker-openssl.cnf
    /usr/bin/openssl req -new -key $KEYDIR/$WORKER_FQDN-worker-key.pem -out $KEYDIR/$WORKER_FQDN-worker.csr -subj "/CN=$WORKER_FQDN" -config /worker-openssl.cnf

    /usr/bin/openssl x509 -req -in $KEYDIR/$WORKER_FQDN-worker.csr -CA $APIKEYDIR/ca.pem -CAkey $CERTS/ca-key.pem -CAcreateserial -out $KEYDIR/$WORKER_FQDN-worker.pem -days 365 -extensions v3_req -extfile /worker-openssl.cnf

}

admin-keys() {
    KEYDIR=$CERTS/admin

    mkdir -p $KEYDIR
    /usr/bin/openssl  genrsa -out $KEYDIR/admin-key.pem 2048

    /usr/bin/openssl req -new -key $KEYDIR/admin-key.pem -out $KEYDIR/admin.csr -subj "/CN=kube-admin"

    /usr/bin/openssl x509 -req -in $KEYDIR/admin.csr -CA $APIKEYDIR/ca.pem -CAkey $CERTS/ca-key.pem -CAcreateserial -out $KEYDIR/admin.pem -days 365

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
        *)
            print-usage
            ;;
    esac
}

parse-cmd

#!/bin/bash

print-usage() {
    echo "Usage: $0 <api <node_fqdn> <node_ip>|
                     admin|
                     worker <node_fqdn> <node_ip>>|
                     all <node_fqdn> <node_ip>>"
    exit 1
}

CMD=$1
NODE_FQDN=$2
NODE_IP=$3

MASTER_HOST=$2

CERTS=/certs

ADMINDIR=$CERTS/admin
WORKERDIR=$CERTS/workers/$WORKER_FQDN
CA=$CERTS/ca.pem
CA_KEY=$CERTS/ca-key.pem

admin-keys() {
    CSR=$ADMINDIR/admin.csr

    mkdir -p $ADMINDIR

    /usr/bin/openssl  genrsa -out $ADMINDIR/admin-key.pem 2048

    /usr/bin/openssl req -new -key $ADMINDIR/admin-key.pem -out $CSR -subj "/CN=kube-admin"

    /usr/bin/openssl x509 -req -in $CSR -CA $CA -CAkey $CA_KEY -CAcreateserial -out $ADMINDIR/admin.pem -days 365

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

    /usr/bin/openssl req -new -key $KEYDIR/$KEYTYPE-key.pem -out $CSR -subj "$SUBJ" -config /openssl.cnf

    /usr/bin/openssl x509 -req -in $CSR -CA $CA -CAkey $CA_KEY -CAcreateserial -out $KEYDIR/$KEYTYPE.pem -days 365 -extensions v3_req -extfile /openssl.cnf

    cp $CA $KEYDIR

    rm $CSR
}

worker-keys() {
    echo "worker: $NODE_FQDN $WORKER_IP"
    #Need to set env variable for use in worker-openssl.cnf
    export WORKER_IP=$WORKER_IP
    CSR=$WORKERDIR/$NODE_FQDN-worker.csr

    node-keys $NODE_FQDN worker "/CN=$NODE_FQDN"

}


api-keys() {

    CSR=$CERTS/apiserver.csr

    /usr/bin/openssl genrsa -out $CA_KEY 2048

    /usr/bin/openssl req -x509 -new -nodes -key $CA_KEY -days 10000 -out $CA -subj "/CN=kube-ca"

    node-keys $NODE_FQDN apiserver "/CN=kube-apiserver"

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
            ;;
        *)
            print-usage
            ;;
    esac

    #maybe tar and send to stdout
    if [ "$TAR_TO_STDOUT" = "" ]
    then
        echo "Wrote keys to /certs. Set TAR_TO_STDOUT environment variable to output a tar to stdout."
    else
        tar -cf - /certs
    fi

}

parse-cmd

FROM gliderlabs/alpine:3.4

MAINTAINER Seth Lakowske <lakowske@gmail.com>

ENV CERTS=/certs

RUN apk-install openssl bash

ADD ./openssl.cnf /
ADD ./worker-openssl.cnf /
ADD ./k8s-keys.sh /

RUN chmod 755 /k8s-keys.sh

CMD /k8s-keys.sh

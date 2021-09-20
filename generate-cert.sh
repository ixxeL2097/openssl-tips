#!/bin/bash

openssl req -x509 \
            -newkey rsa:2048 \
            -sha256 \
            -days 3560 \
            -nodes \
            -keyout ca-private.key \
            -out ca-server.pem \
            -subj '/C=FR/O=k3s/CN=k3s' \
            -extensions san \
            -config <( \
            echo '[req]'; \
            echo 'distinguished_name=req'; \
            echo '[san]'; \
            echo 'subjectAltName=DNS:kubernetes,DNS:kubernetes.default,DNS:kubernetes.default.svc,DNS:kubernetes.default.svc.cluster.local,DNS:localhost,IP:192.168.0.150,IP:0.0.0.0,IP:10.43.0.1,IP:192.168.64.2,IP:192.168.64.3,IP:127.0.0.1')

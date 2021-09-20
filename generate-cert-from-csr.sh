#!/bin/bash

openssl x509 -req \
             -days 3560 \
             -in server.csr \
             -CA ca-server.pem \
             -CAkey ca-private.key \
             -CAcreateserial \
             -out k3s-new-server.crt \
             -extensions req_ext \
             -extfile req.conf

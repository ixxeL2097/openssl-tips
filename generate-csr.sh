#!/bin/bash

openssl req -new \
            -newkey rsa:2048 \
            -sha256 \
            -nodes \
            -keyout private-csr.key \
            -out server.csr \
            -config req.conf \

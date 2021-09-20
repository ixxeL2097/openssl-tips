# 01 - General

## Fetching information

How to fetch a certificate from a server :

```shell
openssl s_client -showcerts -connect 192.168.0.150:37389 | openssl x509 -outform PEM > cert.cert
```

How to read information about a certificate :

```shell
openssl x509 -in k3s-default.crt -noout -text
```

How to get certificate serial number :

```shell
openssl x509 -noout -serial -in cert.crt
openssl x509 -noout -serial -in cert.crt | cut -d'=' -f2 | sed 's/../&:/g;s/:$//'
```

## Generating certificate

Generate a CA certificate able to sign csr:

```bash
openssl req -x509 \
            -newkey rsa:2048 \
            -sha256 \
            -days 3560 \
            -nodes \
            -keyout private.key \
            -out server.pem \
            -addext keyUsage=critical,digitalSignature,keyEncipherment,keyCertSign \
            -subj '/C=FR/O=k3s/CN=k3s-server-ca'
```

To generate a certificate that include SAN (DNS and IP address) use the following command:

```bash
openssl req -x509 \
            -newkey rsa:2048 \
            -sha256 \
            -days 3560 \
            -nodes \
            -keyout private.key \
            -out server.pem \
            -subj '/C=FR/O=k3s/CN=k3s' \
            -extensions san \
            -config <( \
            echo '[req]'; \
            echo 'distinguished_name=req'; \
            echo '[san]'; \
            echo 'subjectAltName=DNS:kubernetes,DNS:kubernetes.default,IP:192.168.0.150')
```

## Generating signed certificate from CSR

You can also generate a certificate signing request and then sign it with a CA cert. 
Before executing all these commands, you need to generate a `cacert.pem` and `cacert.key` first to sign later your csr (you can use commands above to generate these files).

You need a `req.conf` file to specify requirements for the CSR:

```bash
[req]
distinguished_name = dn
req_extensions = req_ext
prompt = no
[dn]
C = FR
L = Lille
O = fredcorp
OU = IT
CN = k3s.fredcorp.com
[req_ext]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @san
[san]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = localhost
DNS.5 = k3s.fredcorp.com
IP.1 = 192.168.0.150
IP.2 = 192.168.64.2
IP.3 = 192.168.64.3
IP.3 = 127.0.0.1
IP.4 = 10.43.0.1
IP.5 = 0.0.0.0
```

Then generate the csr passing the `req.conf` file as a config parameter :

```bash
openssl req -new \
            -newkey rsa:2048 \
            -sha256 \
            -nodes \
            -keyout private-csr.key \
            -out server.csr \
            -config req.conf \
```

You can check the csr information :

```console
[root@workstation]# openssl req -text -noout -verify -in server.csr
verify OK
Certificate Request:
    Data:
        Version: 1 (0x0)
        Subject: C = FR, L = Lille, O = fredcorp, OU = IT, CN = k3s.fredcorp.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:d7:ea:8e:45:74:b3:90:4b:79:36:f4:a4:e3:f9:
                    c9:df:81:58:bf:90:d4:71:31:66:fb:5b:9c:d5:01:
                    42:e9:6d:da:1d:23:2d:b7:cf:0d:42:6a:71:39:33:
                Exponent: 65537 (0x10001)
        Attributes:
        Requested Extensions:
            X509v3 Key Usage:
                Key Encipherment, Data Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Alternative Name:
                DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, DNS:k3s.fredcorp.com, IP Address:192.168.0.150, IP Address:192.168.64.2, IP Address:127.0.0.1, IP Address:10.43.0.1, IP Address:0.0.0.0
    Signature Algorithm: sha256WithRSAEncryption
         11:5c:2f:6b:d3:c9:10:3e:3d:f8:b5:41:a7:d1:b0:c6:9c:08:
         1b:f2:a4:c8:f4:26:0f:d7:13:06:15:d2:fb:b1:57:10:40:64:
         f5:8c:90:cd:43:bd:f7:d1:a2:77:98:2a:36:30:64:cd:de:9d:
```

Next we will use this CSR to generate our SAN certificate:

```bash
openssl x509 -req \
             -days 3560 \
             -in server.csr \
             -CA cacert.pem \
             -CAkey cakey.pem \
             -CAcreateserial \
             -out server.crt \
             -extensions req_ext \
             -extfile req.conf
```

and then check your new certificate :

```console
[root@workstation]# openssl x509 -text -noout -in k3s-server-new.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            2f:bd:ac:ea:e3:bc:ca:0c:ce:78:5b:51:56:40:32:f0:be:4d:6c:f8
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = FR, O = k3s, CN = k3s-server-ca
        Validity
            Not Before: Sep 20 09:22:01 2021 GMT
            Not After : Jun 20 09:22:01 2031 GMT
        Subject: C = FR, L = Lille, O = fredcorp, OU = IT, CN = k3s.fredcorp.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:d7:ea:8e:45:74:b3:90:4b:79:36:f4:a4:e3:f9:
                    c9:df:81:58:bf:90:d4:71:31:66:fb:5b:9c:d5:01:
                    42:e9:6d:da:1d:23:2d:b7:cf:0d:42:6a:71:39:33:
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage:
                Key Encipherment, Data Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Alternative Name:
                DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, DNS:k3s.fredcorp.com, IP Address:192.168.0.150, IP Address:192.168.64.2, IP Address:127.0.0.1, IP Address:10.43.0.1, IP Address:0.0.0.0
    Signature Algorithm: sha256WithRSAEncryption
         a9:69:97:a3:00:d2:b3:0d:fc:f1:7d:b4:40:1c:4c:9e:6b:dd:
         aa:a5:f0:ad:8e:61:0f:dc:80:36:64:19:75:42:eb:05:2a:e3:
         a0:16:d9:02:83:2b:9f:d3:ab:d3:32:4a:15:27:a4:1e:04:43:
```

#!/bin/bash

echo "Generate CA Cert ==="
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

echo "Generate admin User Client Cert ==="
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin.json | cfssljson -bare admin

echo "Generate kube-controller-manager Client Cert ==="
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  controller-manager.json | cfssljson -bare controller-manager

echo "Generate kube-apiserver Server Cert ==="
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  apiserver.json | cfssljson -bare apiserver

echo "Generate Service Account Client Cert ==="
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account.json | cfssljson -bare service-account

echo "Convert to crt/key File Extentions ==="
mv ca.pem ca.crt
mv ca-key.pem ca.key
mv admin.pem admin.crt
mv admin-key.pem admin.key
mv controller-manager.pem controller-manager.crt
mv controller-manager-key.pem controller-manager.key
mv apiserver.pem apiserver.crt
mv apiserver-key.pem apiserver.key
mv service-account.pem service-account.crt
mv service-account-key.pem service-account.key

echo "Remove csr Files ==="
rm *.csr

# Generate etcd certs

## Generate CA

### CA Key

```plain
openssl genrsa -out ca.key 2048
```

### CA Cert

```plain
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt

Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:Tennessee
Locality Name (eg, city) []:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Rancher
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:rancher-etcd-ca
Email Address []:
```

## Generate Peer Cert

### Peer Key

```plain
openssl genrsa -out peer.key 2048
```

### Peer Cert Config

Create a `peer.config` file. The alt_names format is `*.<etcd-name>.<namespace>.svc` and `*.<etcd-name>.<namespace>.svc.local`

```plain
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = none
L = none
O = Rancher
OU = none
CN = rancher-etcd-peer

[v3_req]
keyUsage = keyCertSign, cRLSign, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.rancher-etcd.cattle-system.svc
DNS.2 = *.rancher-etcd.cattle-system.svc.local
```

### Peer Cert Request

```plain
openssl req -new -key peer.key -out peer.csr -config peer.config -nodes -sha256
```

### Sign Peer Request

```plain
openssl x509 -req \
  -days 1825 \
  -in peer.csr -out peer.crt \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -extensions v3_req -extfile peer.config
```

## Generate Server Cert

### Server Key

```plain
openssl genrsa -out server.key 2048
```

### Server Cert Config

Create a `server.config` file. We need names for the etcd kubernetes server endpoint, pods and localhost. The alt_names format `*.<etcd-name>.<namespace>.svc` and `*.<etcd-name>.<namespace>.svc.local`

```plain
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = none
L = none
O = Rancher
OU = none
CN = rancher-etcd-server

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.rancher-etcd.cattle-system.svc
DNS.2 = *.rancher-etcd.cattle-system.svc.local
DNS.3 = rancher-etcd-client
DNS.4 = rancher-etcd-client.cattle-system
DNS.5 = rancher-etcd-client.cattle-system.svc
DNS.6 = rancher-etcd-client.cattle-system.svc.local
DNS.7 = localhost
```

### Server Cert Request

```plain
openssl req -new -key server.key -out server.csr -config server.config
```

### Sign Server Request

```plain
openssl x509 -req \
  -days 1825 \
  -in server.csr -out server.crt \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -extensions v3_req -extfile server.config
```

## Generate Client Cert

### Client Key

```plain
openssl genrsa -out client.key 2048
```

### Client Cert Config

Create a `client.config` file.

```plain
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = none
L = none
O = Rancher
OU = none
CN = etcd-client

[v3_req]
keyUsage = keyCertSign, cRLSign, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth
```

### Client Cert Request

```plain
openssl req -new -key client.key -out client.csr -config client.config
```

### Sign Client Request

```plain
openssl x509 -req \
  -days 1825 \
  -in client.csr -out client.crt \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -extensions v3_req -extfile client.config
```

## Create Secrets

```plain
kubectl create ns cattle-system
```

```plain
kubectl -n cattle-system create secret generic tls-rancher-etcd-peer \
  --from-file=peer-ca.crt \
  --from-file=peer.crt \
  --from-file=peer.key
```

```plain
kubectl -n cattle-system create secret generic tls-rancher-etcd-server \
  --from-file=server-ca.crt \
  --from-file=server.crt \
  --from-file=server.key
```

```plain
kubectl -n cattle-system create secret generic tls-rancher-etcd-client \
  --from-file=etcd-client-ca.crt \
  --from-file=etcd-client.crt \
  --from-file=etcd-client.key
```

## Kube-apiserver

```plain
kubectl -n cattle-system create secret generic tls-rancher-k8s-admin \
  --from-file=ca.crt \
  --from-file=tls.crt=admin.crt \
  --from-file=tls.key=admin.key

kubectl -n cattle-system create secret generic tls-rancher-k8s-controller-manager \
  --from-file=ca.crt \
  --from-file=tls.crt=controller-manager.crt \
  --from-file=tls.key=controller-manager.key

kubectl -n cattle-system create secret generic tls-rancher-k8s-apiserver \
  --from-file=ca.crt \
  --from-file=tls.crt=apiserver.crt \
  --from-file=tls.key=apiserver.key

kubectl -n cattle-system create secret generic tls-rancher-k8s-service-account \
  --from-file=ca.crt \
  --from-file=tls.crt=service-account.crt \
  --from-file=tls.key=service-account.key
```

### Create kubeconfig files

controller-manager

```plain
kubectl config set-cluster rancher \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://rancher-kube-apiserver:6443 \
  --kubeconfig=controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=controller-manager.crt \
  --client-key=controller-manager.key \
  --embed-certs=true \
  --kubeconfig=controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=rancher \
  --user=system:kube-controller-manager \
  --kubeconfig=controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=controller-manager.kubeconfig
```

```plain
kubectl -n cattle-system create secret generic kubeconfig-rancher-k8s-controller-manager \
  --from-file=controller-manager.kubeconfig
```


admin

```plain
kubectl config set-cluster rancher \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://rancher-kube-apiserver:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=admin.crt \
  --client-key=admin.key \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=rancher \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig
```

```plain
kubectl -n cattle-system create secret generic kubeconfig-rancher-k8s-admin \
  --from-file=admin.kubeconfig
```

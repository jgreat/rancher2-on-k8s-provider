# Rancher2 on k8s provider

This is a Proof of Concept project for running Rancher 2.x on a K8s provider.

## What are we trying to solve

Rancher 2 normally integrates with the K8s API that its installed on.  This is a problem on providers like AKS/EKS/GKE since the data layer (etcd) is essentally a black box.  Rancher operations rely on the ability to take etcd snapshots for backups and restoration/rollback incase of upgrade failure. Providers tend to scale the etcd backends for "normal" K8s operations, not usually as a database backend.

## Yo dog I heard you like Kubernetes

These instructions walk through creating an etcd cluster and K8s componets on top of a base K8s cluster so Rancher can run off that K8s instead of the provider K8s. Yes, we are creating a K8s instance on your K8s instance so you can run Rancher to manage your K8s instances.

The plan is to utilize the etcd-operator to manage etcd snapshots and restores and use persistent storage that can be scaled to provide better iops performance than the black box backend.

## Credit

Credit where credit is due. A lot of this was complied from examples in kelseyhightower/kubernetes-the-hard-way and etc-operator example documentation.

## Setup

This example uses GKE, since its the easiest provider to get a functional/stable K8s instance on, but any k8s with cloud-provider integration should work.

### Create Cluster

```plain
gcloud container clusters create jgreat-rancher-on-k8s --addons=HorizontalPodAutoscaling --cluster-version=1.12
```

### Install helm tiller

```plain
kubectl -n kube-system create serviceaccount tiller

kubectl create clusterrolebinding tiller \
  --clusterrole cluster-admin \
  --serviceaccount=kube-system:tiller

helm init --service-account tiller --wait
```

### Install etcd-operator

```plain
helm install stable/etcd-operator --name etcd-operator --namespace etcd-operator --set etcdOperator.commandArgs.cluster-wide=true --wait
```

### Install nginx-ingress controller

```plain
helm install stable/nginx-ingress --name nginx-ingress --namespace nginx-ingress --set controller.publishService.enabled=true --set controller.replicaCount=2 --wait
```

### Install Cert-manager

```plain
helm repo add jetstack https://charts.jetstack.io

kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.7/deploy/manifests/00-crds.yaml

helm install jetstack/cert-manager --name cert-manager --namespace cert-manager --version v0.7.0 --wait
```

### Create Namespace

Create namespace so we can add secrets.

```plain
kubectl create namespace cattle-system
```

### Generate SSL for etcd/k8s

There are generic pre-defined cfssl configurations for the etcd and K8s certificates. Grab a copy of cfssl for your system and run the `generate-certs.sh` scripts. The CAs are signed for 10 years and the certs for 9 years. If you're still running this at that point you need to reevaluate your life choices.

#### Install cfssl binaries on your local system

Adjust the version for your system architecture. Place the binaries in a directory in your path.

```plain
curl -s -L -o ~/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -s -L -o ~/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x ~/bin/{cfssl,cfssljson}
```

#### Generate etcd certificates

```plain
cd ssl/etcd
./generate-certs.sh
```

#### Create etcd secrets

```plain
kubectl -n cattle-system create secret generic tls-rancher-etcd-peer \
  --from-file=peer-ca.crt \
  --from-file=peer.crt \
  --from-file=peer.key

kubectl -n cattle-system create secret generic tls-rancher-etcd-server \
  --from-file=server-ca.crt \
  --from-file=server.crt \
  --from-file=server.key

kubectl -n cattle-system create secret generic tls-rancher-etcd-client \
  --from-file=etcd-client-ca.crt \
  --from-file=etcd-client.crt \
  --from-file=etcd-client.key
```

#### Generate k8s certificates

```plain
cd ../k8s
./generate-certs.sh
```

#### Generate k8s kubeconfig files

```plain
./generate-kubeconfigs.sh
```

#### Create k8s secrets

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
  --from-file=tls.key=service-account.key\

kubectl -n cattle-system create secret generic kubeconfig-rancher-k8s-controller-manager \
  --from-file=controller-manager.kubeconfig

kubectl -n cattle-system create secret generic kubeconfig-rancher-k8s-admin \
  --from-file=admin.kubeconfig
```

### Install Rancher

```plain
cd ../../
helm install ./rancher --name rancher --namespace cattle-system \
  --set k8sBackend=discrete \
  --set replicas=1 \
  --set addLocal=false \
  --set hostname=jgreat-rancher-test-1.eng.rancher.space
```

## Things that don't work

* Only 1 replica - Turned off service-account/CATTLE_NAMESPACE/CATTLE_PEER_SERVICE options.
* No "local" cluster - Need to be able to define an "admin cluster"

## Things to improve

### SSL

* Update cert-manager to support client cert creation (might work now, need to see extentions on certs)
* Update etcd-operator to support the standard tls type secret.
* Way to generate kubeconfig files.

## Things that need to be worked out

* backups
* restores
* rollback Rancher versions.

## Testing Etcd

```plain
kubectl -n cattle-system apply -f util/etcd-client.yaml

kubectl -n cattle-system exec -it etcd-client-<pod> /bin/sh

cd /data/ssl
export ETCDCTL_API=3
etcdctl --endpoints=https://rancher-etcd-client:2379 --cert=etcd-client.crt --key=etcd-client.key --cacert=etcd-client-ca.crt member list -w table
```

## Testing Kubernetes

```plain
kubectl -n cattle-system apply -f util/k8s-client.yaml

kubectl -n cattle-system exec -it k8s-client-<pod> /bin/bash

export KUBECONFIG=/data/k8s/admin.kubeconfig
kubeconfig get cs
```

#!/bin/bash

echo "Generate admin.kubeconfig ==="
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


echo "Generate controller-manager.kubeconfig ==="
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


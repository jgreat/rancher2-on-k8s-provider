{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rancher.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "rancher.fullname" -}}
  {{- $name := default .Chart.Name .Values.nameOverride -}}
  {{- if contains $name .Release.Name -}}
    {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{- define "etcd.fullname" -}}
  {{- $name := default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
  {{- if contains $name .Release.Name -}}
    {{- $fullname := .Release.Name | trunc 63 | trimSuffix "-" -}}
    {{- printf "%s-etcd" $fullname | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- $fullname :=  printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
    {{- printf "%s-etcd" $fullname | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{- define "kubeApiServer.fullname" -}}
  {{- $name := default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
  {{- if contains $name .Release.Name -}}
    {{- $fullname := .Release.Name | trunc 63 | trimSuffix "-" -}}
    {{- printf "%s-kube-apiserver" $fullname | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- $fullname :=  printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
    {{- printf "%s-kube-apiserver" $fullname | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{- define "kubeControllerManager.fullname" -}}
  {{- $name := default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
  {{- if contains $name .Release.Name -}}
    {{- $fullname := .Release.Name | trunc 63 | trimSuffix "-" -}}
    {{- printf "%s-kube-controller-manager" $fullname | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- $fullname :=  printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
    {{- printf "%s-kube-controller-manager" $fullname | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

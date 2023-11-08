#!/bin/bash

for ns in $(kubectl get ns -o custom-columns=name:.metadata.name); do
  echo "Cleaning Pods in: $ns"
  kubectl get pods --namespace "$ns" --no-headers | grep -v Running | awk '{print $1}' | xargs echo
  kubectl get pods --namespace "$ns" --no-headers | grep -v Running | awk '{print $1}' | xargs kubectl delete pods --namespace "$ns"
done


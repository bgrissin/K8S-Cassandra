#!/bin/bash

kubectl delete -f StorageClass/px-storageclass.yaml
kubectl delete -f cassandra-service.yaml
kubectl delete -f cassandra-statefulset.yaml

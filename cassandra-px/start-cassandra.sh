#!/bin/bash

kubectl create -f StorageClass/px-storageclass.yaml
kubectl create -f cassandra-service.yaml
kubectl create -f cassandra-statefulset.yaml

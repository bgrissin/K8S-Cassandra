#!/bin/bash

kubectl create -f cassandra-service.yaml
kubectl create -f cassandra-statefulset.yaml

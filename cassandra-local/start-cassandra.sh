#!/bin/bash

kubectl create -f cassandra-service.yaml
#kubectl create -f cassandra-peer-service.yaml
kubectl create -f cassandra-replica-controller.yaml

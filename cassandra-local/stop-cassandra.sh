#!/bin/bash

kubectl delete -f cassandra-service.yaml
#kubectl delete -f cassandra-peer-service.yaml
kubectl delete -f cassandra-replica-controller.yaml

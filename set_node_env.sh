#!/bin/bash
#
# bgrissin@cassandra1:~$ kubectl get pods -o wide
# NAME          READY     STATUS    RESTARTS   AGE       IP            NODE
# cassandra-0   1/1       Running   0          15h       10.244.1.19   cassandra3
# cassandra-1   1/1       Running   1          15h       10.244.2.15   cassandra2
# cassandra-2   1/1       Running   0          15h       10.244.0.16   cassandra1


NODE_3_IP=10.244.1.19
NODE_2_IP=10.244.2.15
NODE_1_IP=10.244.0.16

#export NODE_3_IP=10.244.1.19&&export NODE_2_IP=10.244.2.15&&export NODE_1_IP=10.244.0.16

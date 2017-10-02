For this test we use volumes that are dynamically created by PX adding the storage volume configurations into a storageclass.

The volumes in this lab are also consumed by cassandra stateful PODs that are also deployed via a K8S statefulset service using a headless service called cassandra.  The difference in this lab from the local mount lab, is the volumes are dynamically created and managed on nodes that need a volume where a cassandra POD is scheduled.  Each Cassandra POD is also configured for Cassandra to use 2 replicas.  

To start stop or get the status ofthe PODs or the status of the cassandra cluster using nodetool are scripted into three different scripts

1) start-cassandra.sh
2) stop-cassandra.sh
3) status-check.sh

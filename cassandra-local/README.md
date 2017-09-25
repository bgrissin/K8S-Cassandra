For this test we use existing volumes (/var/lib/cassandra/data) on each host that were created and formatted when we setup our K8S cluster nodes.

These local volumes are consumed by cassandra stateful PODs that are deployed via a K8S statefulset service using a headless service called cassandra.  Each Cassandra POD is also configured for Cassandra to use 2 replicas.  

To start stop or get the status ofthe PODs or the status of the cassandra cluster using nodetool are scripted into three different scripts

1) start-cassandra.sh
2) stop-cassandra.sh
3) status-check.sh

# Cassandra and PX - BuR for modernized enterprise application stacks

New application architectures and methodologies for building, saving, and running enterprise application stacks are having a profound impact on how we manage underlying storage and data.   With these changes arrives challenges as to how we continue to manage data and storage that meets or exceeds business regulatory requirements such as Backup and Disaster Recovery (BuR) plans.   

In this post, our objective is to demonstrate how we can utilize PX from PortWorx to improve our BuR plans by improving Recovery Time Objectives (RTO) for stateful containerized application stacks.    RTO is a key metric used to assess business application production readiness by measuring the amount of time required to recover an application to an acceptable state in the event of an outage.  Recovery Point Objectives (RPO) are also part of the application production readiness picture as this metric defines what data sets are adequate recovery restore points.  As application and and transactions increase, the amount of data generated beyond the last known good restore point increases, thus creating potentially unacceptable recovery restore points.   Generally speaking, if your DR recovery plans are taking to long to recover, or your no longer able to acquire acceptable recovery points and at accceptable intervals; then your stateful containerized application stack disaster recovery plans need data and storage management solutions from PortWorx.   

We chose to show Cassandra running as a stateful service on a K8S cluster to reveal how we can greatly improve some common recovery point obstacles for containerized stateful work loads.  Cassandra clusters can be configured to recover all application data to a current state  recovery point using eventual consistency.   Cassandra cluster nodes recover in two distinct stages, bootstrapping and repair.   Bootstrapping are the processes that during a failure, a new cluster member is joined a new node to the existing ring and all data from a last known restore point known within the cluster from other running cluster members is restored.   When bootstrapping finishes, repair steps are then executed, where all transactions that occurred during the bootstrap stage are also written to the new Cassandra recovery node as well.   Eventual consistency is a great RPO story, especially for transactional applications that need robust capabilities to recover all data and transactions to a current state.  However, increasing amounts of transactions and data will begin to impact RTO by increasing the amount of time it will take to recover all data during both recovery stages, bootstrap and repair, thus creating a situation where eventual consistency can become too slow or is never achieved due to the increasing volume.   This kind of situation is one example where significant value is brought forward using PX as a storage and data management solution to help improve existing recovery plan deficiencies.   

For this demo, we are going to use a kubernetes cluster of three nodes consisting of 1 tainted master node and 2 additional worker hosts.  We will run stateful PODs utilizing single ring Cassandra clusters across two of three K8S nodes, leaving one empty node available to be brought in as a additional node to support our planned failure events.

There will be two seperate tests within this demo and all hosts in both test environments will use identical attached storage configurations. In both tests, stateful workloads will be created using Persistent Volumes and Persistent Volume Claims to request and consume locally mounted volumes in the first test and in line created PX volumes via the pxcli for the second test.   Portworx does offer the ability to dynamically allocate storage on demand instead of having to manually provision PX storage volumes in line, but for this demo it was decided to use in line created PX volumes, as we wanted to be able to visually and comparitively display with more depth and clarity where PX provides improvements.   We are going to capture the amount of time it takes to recover a failed Cassandra cluster node  in both tests.   We are also going to capture IOPS performance during each test while the bootstrap restore process is running, to further reveal how PX also provides faster disk performance along with faster recovery times.     

It is not recommended to use this demo confguration for production environments.  For example, its typical for most large clusters running in production, making use of PX dynamic provisioning storage volumes in order to reduce administration burdens and complexities while increasing continous delivery speeds by incorporating automation.  

# Test 1



# Test 2








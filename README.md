# Kubernetes, Cassandra, and PX  

![](images/PXK8S.tiff) ![](images/PXK8S.tiff)    

## BuR for modernized enterprise application stacks

New application architectures and methodologies for building, saving, and running enterprise application stacks are having a profound impact on how we manage underlying storage and data.   With these changes arrives challenges as to how we continue to manage data and storage that meets or exceeds business regulatory requirements such as Backup and Disaster Recovery (BuR) plans.   

In this post, our objective is to demonstrate how we can utilize PX from PortWorx to improve our BuR plans by improving Recovery Time Objectives (RTO) for stateful containerized application stacks.    RTO is a key metric used to assess business application production readiness by measuring the amount of time required to recover an application to an acceptable state in the event of an outage.  Recovery Point Objectives (RPO) are also part of the application production readiness picture as this metric defines what data sets are adequate recovery restore points.  As application use and transactions increase, the amount of data generated beyond the last known good restore point increases, thus creating potentially unacceptable recovery restore points.   Generally speaking, if your DR recovery plans are taking to long to recover, or your no longer able to acquire acceptable recovery points and at accceptable intervals; then your stateful containerized application stack disaster recovery plans need data and storage management solutions from PortWorx.   

We chose to show Cassandra running as a stateful service on a K8S cluster to reveal how we can greatly improve some common recovery  obstacles for containerized stateful work loads.  Cassandra clusters can be configured to recover all application data to a current state  recovery point with eventual consistency.   Cassandra cluster nodes recover in two distinct stages, bootstrapping and repair.   Bootstrapping are the processes during a failure, a new cluster member is joined to the existing ring and all data from a last known restore point known within the cluster from other running cluster members is restored.   When bootstrapping finishes, repair steps are then executed, where all transactions that occurred during the bootstrap stage are also written to the new Cassandra recovery node as well.   Eventual consistency is a great RPO story, especially for transactional applications that need robust capabilities to recover all data and transactions to a current state.  However, increasing amounts of transactions and data will begin to impact RTO by increasing the amount of time it will take to recover all data during recovery, thus creating a situation where eventual consistency can become too slow or is never achieved.   This kind of situation is one example where significant value is brought forward using PX as a storage and data management solution to help improve similar recovery plan deficiencies.   

For this demo, we are going to use a kubernetes cluster consisting of three nodes, 1 tainted master node and 2 additional worker hosts.  We will run stateful PODs to deploy replicated Cassandra clusters across two of three K8S nodes, leaving one empty node available to be brought in as a additional node to support our planned failure events.  

There will be two seperate tests within this demo and all hosts in both test environments will use identical attached storage configurations. In both tests, stateful workloads will be created using Persistent Volumes and Persistent Volume Claims to request and consume locally mounted volumes in the first test and PX volumes created using a storageclass for the second test.  We are going to capture the amount of time it takes to recover a failed Cassandra cluster node in both tests.   We are also going to capture IOPS performance during each test while the bootstrap restore process is running, to further reveal how PX also provides faster disk performance along with faster recovery times.     

It is not recommended to use this demo confguration for production environments.  

## Setting up the environment

This lab can be run on many public or private platforms.   It was desired to show these labs in an environment as similar to an on premises bare metal environment as we could achieve, but without having to buy physical servers and setting them up,  so Packet.net was selected to build our platform and labs for this repo.

First, log into Packet.net and create three type0 instances, and name them cassandra1, cassandra2 and cassandra3.   Also create 6 volumes and attach a pair of volumes to each host instance.   You can also name the volume pairs individually if you want.  on each host instance, one of the volumes will be a local mounted and managed volume and the other will be a PX managed volume.

initiate SSH sessions into the first cassandra instance (cassandra1) and clone this repo.  Also initiate ssh sessions to the other instances (cassandra2 and cassandra3)


# [Create your K8S cluster](K8S_create/K8S_setup.md)


# [Cassandra using local volumes](cassandra-local/README.md)


# [Cassandra using Portworx PX volumes](cassandra-px/README.md)


## Summary





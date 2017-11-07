# Kubernetes, Cassandra, and PX  

![](images/px_k8s.png)    ![](images/cassandra.png)    

## BuR for modernized enterprise application stacks

New application architectures and methodologies for building, saving, and running containerized enterprise application stacks are having a profound impact on how we manage underlying storage and data.  Implementing strategies such as backup and recovery or building highly available application stacks that are able to maintain underlying storage and data consistency are critical stories that solutions such as  PX from Portworx address.   This post demonstrates some of the advantages for using a solution like Portworx PX versus using traditional local storage solutions.  

One of the objectives this post intends to demonstrate is how PX from PortWorx can improve BuR plans by improving Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO) for stateful containerized application stacks.    RTO is a key metric used to assess business application production readiness by measuring the amount of time required to recover an application to an acceptable state in the event of an outage.  RPO is also part of the application production readiness picture as this metric defines what data sets are adequate recovery restore points.  As application use and transaction numbers increase, the amount of data generated beyond the last known good restore point increases, thus creating potentially unacceptable recovery restore points.   Generally speaking, if your DR recovery plans are taking to long to recover, or your no longer able to acquire acceptable recovery points and at accceptable intervals; then your stateful containerized application stack disaster recovery plans need data and storage management solutions from PortWorx.   

Cassandra running as a statefulset service on a K8S cluster is a good example how to greatly improve some common recovery obstacles for containerized stateful work loads.  Applications that use Cassandra backed database clusters can be configured to recover all committed and transactional data to the most current recovery point possible with eventual consistency.   Cassandra cluster nodes recover in two distinct stages, bootstrapping and repair.   Bootstrapping are the processes during a failure, a new cluster member is joined to the existing ring and all data from a last known restore point known within the cluster from other running cluster members is restored.   When bootstrapping finishes, repair steps are then executed, where all transactions that occurred during the bootstrap stage are also written to the new Cassandra recovery node as well.   Eventual consistency is a great RPO story, especially for transactional applications that need robust capabilities to recover all data and transactions to a current state.  However, increasing amounts of transactions and data can impact RTO by increasing the amount of time it takes to recover all data during recovery, thus creating a situation where eventual consistency can become too slow or is never achieved.   This kind of situation is one example where significant value is brought forward using PX as a storage and data management solution to help improve similar recovery plan deficiencies.   

This demo makes use of a kubernetes cluster consisting of three nodes, 1 tainted master node and 2 additional worker hosts.   Statefulset  PODs are deployed as replicated Cassandra clusters across two of three K8S nodes, leaving one empty node available to be brought in as a additional node to support our planned failure events.  

There are two seperate tests available to run, one which uses local storage and a second that uses PX managed stroage.   All hosts in both tests will use identical attached storage configurations using the same hosts.   In both tests, statefulset workloads will be deployed, each with a headless service that acts as the casssandra cluster seed provider for holding information such as private IPs for all cassandra PODs can talk to one another across their respective rings.       

Thes labs are not intended for production environments.  

## Get some Infrastructure

This lab can be run on many public or private platforms.   Packet.net was chosen as the platform for these labs because it close resemblance to an on premises experience.

First, log into Packet.net and create three type0 instances, and name them cassandra1, cassandra2 and cassandra3.   Also create 6 volumes and attach a pair of volumes to each host instance.  For each host instance, one of the volumes will act as a locally mounted volume and the other will be a PX managed volume.  Once two volumes are attached to each instance, the setup for those volumes is covered in section below titled 'Create a K8S cluster'

Initiate and test SSH sessions into the first cassandra instance (cassandra1) and clone this repo.  Also initiate ssh sessions to the other instances (cassandra2 and cassandra3)


# [Create a K8S cluster](K8S_create/K8S_setup.md)


# [Cassandra using local volumes](cassandra-local/README.md)


# [Cassandra using Portworx PX volumes](cassandra-px/README.md)


## Summary





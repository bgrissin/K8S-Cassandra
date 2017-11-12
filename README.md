# Kubernetes, Cassandra, and PX  

![](images/px_k8s.png)    ![](images/cassandra.png)    

## BuR for modernized enterprise application stacks

New application architectures and methodologies for building, saving, and running containerized enterprise application stacks are having a profound impact on how we manage underlying storage and data.  Implementing strategies for backup and recovery (BuR) or building highly available and resilient application stacks that are able to maintain underlying storage and data consistency are critical stories that solutions such as PX from Portworx helps address.   

The primary objective these labs intend to demonstrate is how PX from PortWorx can improve availability and BuR plans by using PX's dynamic provisioning in tandem with K8S cluster services defined within statefulset definitions.  Adding PX Dynamic Provisioning capabilities into K8S statefulset service defintions will provide key improvements for application availability, resiliency, and BuR metrics such as Recovery Time Objectives (RTO), and Recovery Point Objectives (RPO).  RTO is a key metric used to assess business application production readiness by measuring the amount of time required to recover an application to an acceptable state in the event of an outage.  RPO is also part of the application production readiness picture as this metric defines what data sets are adequate recovery restore points.  As application use and transaction numbers increase, the amount of data commited and the amount of transations that can occur beyond the last known good commit restore point can both increase restore times significantly, thus creating potentially unacceptable BuR objectives.   Generally speaking, if your recovery plan restores are taking to long to recover or scale; then your stateful containerized application stacks need data and storage management features provided by PX from PortWorx.   

Cassandra running as a statefulset service on a K8S cluster is a good example how one can begin to solve many common failover, availability, and resiliency issues for containerized work loads that require persistent volumes and data.  Application stacks that use a Cassandra backed database can be configured to recover all committed and uncommited data to the most current recovery point possible with eventual consistency.   Cassandra provides mechanisms for recovery or scale events during two distinct stages when adding new or replacement members, bootstrapping and repair.   Bootstrapping are the processes to restore all data from a last known good and commited restore point available from within the rest of cluster that is still healthy.   When bootstrapping finishes, repair steps are then executed, where all transactions that occurred during the bootstrap stage are also written to the new Cassandra member as well.   Eventual consistency is a great BuR story, especially for transactional application stacks that need robust capabilities to recover all transactions to a current state.  However, increasing volumes of transactions or the time it takes to restore commited restore points can impact BuR objectives by increasing the amount of time it takes to recover all data beyond acceptable service levels, thus creating a situation where eventual consistency can become too slow or is never achieveable.   This kind of situation is one example where significant value is brought forward using PX as a storage and data management solution to help improve or solve eventual consistency recovery plan deficiencies.   

This demo makes use of a kubernetes cluster consisting of three nodes, 1 tainted master node and 2 additional worker hosts.   Statefulset  PODs are deployed as replicated Cassandra clusters across two of three K8S nodes, leaving one empty node available to be brought in as a additional node to support our planned failure and scale events.  

There are two seperate tests available to run, one which uses local storage and a second that uses PX managed storage.   All hosts in both tests will use identical attached storage configurations using the same hosts.   In both tests, statefulset workloads will be deployed, each with a headless service that acts as the casssandra cluster seed provider for holding information such as private IPs for all cassandra PODs can talk to one another across their respective rings.       

These labs are not intended for production environments.  

# [Create a K8S cluster](K8S_create/K8S_setup.md)


# [Cassandra using local volumes](cassandra-local/README.md)


# [Cassandra using Portworx PX volumes](cassandra-px/README.md)


## Summary

- The automation capabilities while using PX dynamic provisioning are a devops dream.   The simplification, increased visibility, and management of container volumes, combined with the reduction code required to automate and align stateful portions of your stacks to applicable stateless layers is minimal and seemless with PX.   Soon, a PX release with its own dedicated embedded key store is scheduled to be released, instead of having to install yet another etcd or consul.  Using PX offers many advantages to improve devops efforts by providing many opportunities to improve automatation pipelines and at the same time reduce complexities and technical debt.  For those who have already developed their persistent stacks, you can make use of PX's V2 Docker plugin capability to easily tie in the PX solution without having to rewrite your stack defintions.

- The introduction of a storage manaagement layer for container workloads within a CAAS or PAAS is long overdue and has arrived to the enterprise with PX.  Enterprises have begun to recoginze the need for a persistent data and storage management capability that provides deep levels of storage visibility that are not available in traditional SAN or NAS management tools.   Having a storage management layer that is tied directly into the container stacks where a storage admin can quickly see what PODs and containers are consuming which volumes across an entire container platform, that is perhaps using several storage backends, is a requirement for running production grade environments.

- BuR capabilities brought forward by PX vastly improves availability, resiliency, and achieves recovery objectives that require  underlying storage for persistent data.  Building recovery and availability strategies for every application stack that consumes storage differently, adds too much extra unique automation to each stack and pipeline, thus increasing devops development times and increasing the margins for error for successful scale and recovery requests.  Additionally, using features within PX such as snap to enhance scale or recovery of storage volumes, especially when using multidata center environments, will yield incredible improvements and possibilities for multi-region scale and resiliency and also achieving recovery times that meet .

- Last, when measuring IOPS performance using iostat during these labs, TPS (transactions per second) on PX volumes revealed a pleasant bonus by revealing significant performance improvements compared to using traditionally mounted volumes.   The TPS captured during these labs revealed very compelling performance numbers that should be of interest to any who are looking for improvements in overall speed or have workloads that suffer from high iowait times or have high CPU idle times for stateful applications on various hosts.   We often overlook its possible underlying storage on hosts running container application stacks can be a root cause for processes that have latency issues such as high CPU idle time, or high iowaits.   Using PX helps improve the speed natively, but also provides the management layer and visibility often needed to isloate and identify where storage bottlenecks are occuring within complex stacks across many hosts and many stacks.   [Here](images/TPS_details.pdf) are some saved performance graphs from some previous executions of these labs for those who want a peak at the numbers without having run the labs.


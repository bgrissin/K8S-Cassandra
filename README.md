# Cassandra and PX - BuR for modernized enterprise application stacks

New application archtiectures and methodologies for building, saving, and running our enterprise application stacks are having a profound impact on how we manage underlying storage and data.   With these changes arrives challenges to how we continue to manage data and storage that keeps consistency with business regulatory requirements such as Backup and Disaster Recovery (BuR) planning.   

In this post, our objective is to demonstrate how we can utilize PX from PortWorx to improve Recovery Time Objectives (RTO) for stateful containerized application stacks.    RTO is a key metric used to assess business application production readiness by measuring the amount of time required to recover an application to an acceptable state in the event of outages.  Recovery Point Objectives (RPO) are also part of the application production readiness picture as this metric defines what are adequate recovery restore points.  Application scale and growth can quickly begin to exceed what is able to be captured at adequate intervals that are considered acceptable restore points.   Generally speaking, if your DR recovery is taking to long to fulfill recovery events, or your no longer able to acquire acceptable recovery point intervals; then your stateful containerized application stack backup and disaster recovery plans need data and storage management solutions from PortWorx.   

We chose to show Cassandra running as a stateful service on a K8S cluster to reveal how we can greatly improve availablility and recovery for stateful work loads.  Cassandra clusters can be configured to recover all application data, including all data generated during  recover times, thus completly.   Cassandra clusters recover and scale in two distinct stages, bootstrapping and repair.   Bootstrapping is the process that recognizes a failure or scale request has occurred and then executes processes to join a new node to the ring and build/recover the data from a last known saved restore point.   When bootstrapping finishes, repair steps are then executed, where all transactions that occurred during the bootstrap stage are also captured and written to the new Cassandra recovered node as well.   This is a great RPO story, especially for highly transactional applications that need robust capabilities to recover all data that was already written to disk, but also including all data that was generated during the time it took to perform a recovery process to a most current state.  However, ongoing growth of your application and data will begin to impact RTO, thus increasing and exposing the acceptable amounts of time it can take to recover from node failures.  This situation is one example where significant value is brought forward using PX as a storage and data management solution to help improve recovery plans.   

For this demo, we are going to use kubernetes 1.7x 3 node clusters consisting of 1 tainted master node and 2 additional worker hosts.  We will run stateful set PODs running single ring Cassandra node clusters across two of three K8S nodes, leaving one empty node available to bring in as an additional node.

There will be two seperate tests in this demo.  Both tests will use attached storage to each specific host instance, with Storage Classes being applied for local mount points in the first test and in line created PX volumes via the pxcli for the second test.   Portworx does provide a way to dynamically allocate storage instead of having to manually provision PX storage volumes in line, but for this demo it was decided to use in line created PX volumes, as we wanted to be able to visually display with more depth and calrity where PX provides improvements.   We are going to capture the amount of time it takes to run a Cassandra native bootstrap and repair process to recover from a simulated failure event to that of the amount of time it takes using a Portworx PX volume replica to replace the Cassandra native bootstrap.  In both tests, we are not going to measure the Cassandra repair times, as we would expect them to not be different between scenarios and we are not having any clients connected to the Cassandra cluster creating any new data during the bootstrap stages.  We are also going to capture IOPS performance measurements for each test during the bootstrap restore processes, as doing so will help further reveal how PX also provides faster disk performance along with faster recovery times.     

It is not recommended using this demo confguration for production environments.  Its typical for large K8S clusters running in production to use PX to provision storage volumes dynamically in order to reduce administration burdens and complexities while increasing continous delivery speeds by incorporating automation.  

# Test 1



# Test 2








# Cassandra and PX - BuR for modernized enterprise application stacks

New application archtiectures and methodologies for building, saving, and running our enterprise application stacks are having a profound impact on how we manage underlying storage and data.   With these changes arrives challenges to how we continue to manage data and storage that is consistent with business regulatory requirements such as Backup and Disaster Recovery (BuR) planning.   

In this post, our objective is to demonstrate how we can utilize PX from PortWorx to improve Recovery Time Objectives (RTO) for stateful containerized application stacks.   RTO is a key metric used to assess business application production readiness by measuring the amount of time required to recover or scale an application to an acceptable state in the event of outages or usage spikes.  Recovery Point Objectives (RPO) are also part of the application production readiness picture as this metric defines what are adequate recovery restore points.  Application scale and growth can quickly begin to exceed what is able to be captured at adequate  intervals that are considered acceptable restore points.   Generally speaking, if your DR recovery for is taking to long to fulfill recovery or scale events, or your no longer able to acquire acceptable recovery point intervals; then your stateful containerized application stack backup and disaster recovery plans need data and storage management solutions from PortWorx.   

We chose to show Cassandra running as a stateful service on a K8S cluster to reveal how we can greatly improve scale, availablility and recovery for stateful work loads.  Cassandra clusters can be configured to scale or recover all application data, including all data generated during build or recover times.   Cassandra clusters recover and scale in two distinct stages, bootstrapping and repair.   Bootstrapping is the process that recognizes a failure or scale request has occurred and then executes processes to join a new node to the ring and build/recover the data from a last known saved restore point.   When bootstrapping finishes, repair steps are then executed, where all transactions that occurred during the bootstrap stage are also captured and written to the new Cassandra build/recovery node as well.   This is a great RPO story, especially for highly transactional applications that need robust capabilities to recover all data that was already written to disk, but also including all data that was generated during the time it took to perform a recovery or scale process to the most current state.  However, ongoing growth of your application and data will begin to impact RTO, thus increasing and exposing the acceptable amounts of time it can take to recover or build nodes.  This scenario is one example where significant value is brought forward using PX as a storage and data management solution to improve your overall scale and recovery plans.   

For this demo, we are going to use a kubernetes 1.7x cluster consisting of 1 untainted master node and 3 worker hosts.  We will be running a single K8S stateful POD running a single ring, two Cassandra node cluster.  This configuration allows for an unused remaining node to be available as a failover or scale node for our test scenarios.  

There will be two seperate tests in this demo.  Both tests will have attached dedicated storage to each specific host instance.  In the first test, storage will be presented and consumed as a direct local storage mount point.  In the second test, we will use the PX cli to create PX managed volumes instead of using the locally managed mount points.  Portworx does provide dynamic allocation of storage, but for this demo it was decided to use static in line locally created PX volumes as we wanted to visually display the time and steps where PX provides improvements.   We are going to capture the amount of time it takes to run a Cassandra native bootstrap and repair process to recover from a simulated failure to that of the amount of time using a Portworx PX volume snap to replace the bootstrap steps along with the repair steps.  In both tests, we are not going to measure the Cassandra repair times, as we would expect them to not be different between scenarios.      

It is not recommended using this demo confguration for production environments.  Its typical for large K8S clusters running in production to use PX to provision storage volumes dynamically in order to reduce administration burdens and complexities while increasing continous delivery speeds by incorporating automation.  

Test 1

<link>

Test 2

<link>






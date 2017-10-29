Within this lab, all storage volumes are dynamically created and managed by PX.   The cassandra stateful PODs in this lab are also represented via a K8S headless service called cassandra.  The major difference with this lab from the local volume lab are that storage volumes being used by PODs are dynamically created and managed by PX for each scheduled cassandra POD.   In the previous local stoage lab, storage was manually configured and presented with all requirements on all nodes in the cluster in advance of any scheduled start or scale/failover of the cassandra service.  With dynamic provisioning using PX, changes or fixes to storage can be achived many time directly through editing the headless service.   The cassandra service in this lab is also configured to consist of two replicas.  

Scripts again are provided for starting, stopping or obtaining status of the cassandra cluster

  1) start-cassandra.sh
  2) stop-cassandra.sh
  3) status-check.sh

On the master K8S node as the user (joeuser) configured for use with kubectl, cd into the cassandra-px directory. You should see several files similar to what is shown below.  

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-px$ ls -l
    total 24
    -rw-rw-r-- 1  joeuser joeuser  165   Sep 11 20:20 cassandra-service.yaml
    -rw-rw-r-- 1  joeuser joeuser 2559   Sep 26 10:14 cassandra-statefulset.yaml
    -rw-rw-r-- 1  joeuser joeuser 1221   Sep 25 19:40 README.md
    -rwxrwxr-x 1  joeuser joeuser   99   Sep 22 10:45 start-cassandra.sh
    -rwxrwxr-x 1  joeuser joeuser  859   Sep 13 22:06 status-check.sh
    -rwxrwxr-x 1  joeuser joeuser   06   Sep 22 10:45 stop-cassandra.sh
    drwxr-xr-x  5 joeuser joeuser  170   Oct  9 09:49 StorageClass

Notice the directory and file structure differs compared to the local lab structure. The StorageClass directory and files contain additional configurations used for the installation of PX (px-spec.yaml) and for persistent volumes and volume claims used by in the cassandra statefulset configurations.

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-px$ ls -l StorageClass
    total 16
    -rw-r--r--  1 joeuser  joeuser  3859 Oct  9 09:49 px-spec.yaml
    -rw-r--r--  1 joeuser  joeuser   197 Oct  9 09:49 px-storageclass.yaml

Start the cassandra service from here using the start-cassandra.sh script

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-px$ ./start-cassandra.sh

After a few minutes two pods should be up and running, one pod is named cassandra-0 and another called cassandra-1. Open seperate SSH sessions into both nodes (cassandra2 and cassandra3) where the pods re running. Also open a second SSH session to each node that can be used for monitoring.

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-px$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP          NODE
    cassandra-0   1/1       Running   0          2h        10.244.1.55    cassandra3
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2

As in the previous lab, again you'll want to pay attention to the creation and management of the volumes being consumed by the cassandra statefulset PODs.  First notice the PX binary in /opt/pwx/bin/pxctl.   You can use the pxctl binary to inspect the volumes within a px cluster that have been created and associated to the PVs and PVCs being consumed by the running cassandra statefulset PODs.  Any additional volumes needed to support scale or failover events will also be dynamically created on demand, or you can use the pxctl binary and APIs to intervene and operate within the storage layer manually as well.  

        joeuser@cassandra1:~/K8S-Cassandra/cassandra-px$ /opt/pwx/bin/pxctl v l
         ID			                        NAME						SIZE	HA	SHARED	ENCRYPTED	IO_PRIORITY	SCALE	STATUS
        873541160657077657	pvc-57a80cf7-a1eb-11e7-9e00-0cc47ae545ca	500 GiB	2	no	no		LOW		0	up - attached on 10.100.26.1 *
        433784267271062885	pvc-c2e91c09-a1eb-11e7-9e00-0cc47ae545ca	500 GiB	2	no	no		LOW		0	up - attached on 10.100.26.3 *
        * Data is not local to the node on which volume is attached.

As in the previous local volume lab, the cassandra PODS require storage at startup.  PX prepares and presents all volumes without any in line intervention necessary during startup, instead volumes are created dynamically, on demand, and are aligned for consumption by the service definitions specified within the statefulset persistent claims and volumes.  In the previous local labs, all storage volumes had to be pre-confgured with fdisk, formatted with a useable file system, manually announce the new volume to each kernel or reboot the host and have new volumes mounted persistently prior to starting up, scaling or failing over any PODs. 

The features and capabilities PX dynamic provisioning provides for a distributed container cluster extremely enhances RTO and RPO stories for distributed application container stacks, such as Cassandra running on K8S clusters.  Dynamic provisioning with PX reduces the time and complexities that often increase and impeed successful RPO and RTO objectives that are required to achieve an enterprise production status.   

After connecting via SSH into the cassandra2 host running cassandra, download some test data to the local volume /root.

    root@cassandra2:~/$ curl -o /root/raw_weather_data.csv https://raw.githubusercontent.com/killrweather/killrweather-data/master/data/raw_weather_data.csv

Here is a snip of what the file looks like, and there should be approx. 16M of data after the download completes. Column headers are shown below for reference only, and should not be part of the actual downloaded data.

    wsid,  year, month, day, hour, temperature, dewpoint, pressure, wind_direction, wind_speed, sky_condition, one_hour_precip, six_hour_precip, twenty_four_hour_precip

    725030:14732,2014,  6, 11,  22, 14.4,   0,  1017.6,    0,   0,    ,    18.9,    40,      5.7
    725030:14732,2014,6,11,21,14.4,0,1018.5,0,6,,18.9,40,6.7
    725030:14732,2014,6,11,20,13.9,0,1018.7,0,0,,18.9,40,6.2
    725030:14732,2014,6,11,19,13.9,0,1018.9,0,0,,20,50,5.7
    .
    .
    .

16m of data isn't a very large data set and will load rather quickly into Cassandra. In order to simulate a longer running load time that can monitor across a longer time interval and also stay running during the time it takes to run a failover simulation test while data is loading, you can make several copies of the 16M file and concatenate (cat file1 file2 ... > raw_weather_data.csv) them together until the size of the raw csv file size reaches approximately 1600GB. Loading a 160GB will take much longer and provide a longer time interval that performance measurements can be captured on every cassandra node while data is being loaded and a during failover test.

Next, exec into the cassandra container on the cassandra2 K8S node, and see the data file.

    root@cassandra2:~/$ docker ps | grep cass
    9e43b4308340    gcr.io/google-samples/cassandra@sha256:7eed23532e59f9ea03260d161f7554df1f8cc2aae80bfe9e6e027aa1aeb264d0  "/sbin/dumb-     init /bin"   47 seconds ago      Up 47 seconds  k8s_cassandra_cassandra-1_default_07003905-a2f2-11e7-9e00-0cc47ae545ca_0  

    root@cassandra2:~/$ docker exec -it 9e43b4308340 bash
    
Change your directory to /cassandra_data and run cqlsh from where the data file is located within the container.

    # cd /cassandra_data && cqlsh
    
Also within a second seperate SSH session on each host, start iostat against /dev/dm-1 so that we capture IOPS (the example provided below captures time interval and TPS every 20 seconds and 100 times) during data loading and during the failover test later in this lab.

    $ iostat -mdt /dev/dm-1 20 100 | sed -n -e '1d' -e '/^Device:/d' -e '/^$/d' -e 'p' |sed -e 'N;s/\n/ /' | awk '{ print $2" "$4" - "$5" "$6" "$7; }'

(when testing using locally managed volumes in the other lab, this command above changes to monitor the px managed device /dev/dm-0)

Back to the CQLSH loader screen, execute the following commands to create the keyspaces and tables.

    cqlsh> CREATE KEYSPACE isd_weather_data WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2 };

    cqlsh> use isd_weather_data;

    cqlsh> CREATE TABLE raw_weather_data (wsid text, year int, month int, day int, hour int, temperature double,dewpoint double,pressure double,wind_direction double, wind_speed double, sky_condition text,sky_condition_text text,one_hour_precip double,six_hour_precip double,twenty_four_hour_precip double, PRIMARY KEY ((wsid), year, month, day, hour)) WITH CLUSTERING ORDER BY (year DESC, month DESC, day DESC, hour DESC);
    Begin the data load process. This will take some time depending how large the data file is. Once the loader completes some details about the load process and statistics will be returned.

    cqlsh> COPY raw_weather_data (wsid, year, month, day, hour, temperature, dewpoint, pressure, wind_direction, wind_speed, sky_condition, one_hour_precip, six_hour_precip,twenty_four_hour_precip) FROM 'raw_weather_data.csv' WITH MAXINSERTERRORS = -1;
    
Let the process of loading data into cassandra while capturing performance metrics run until completion. It will be useful to wait at least 5 - 10 minutes before moving onto the next stage of the lab that forces a failover situation so that a reasonable set of data reflecting performance analysis prior to and during data loading taking place is available to analyze.

SSH to the K8S master node, and su to the user created for running kubectl. First check the status of your cassandra PODs. You should see running cassandra PODs on nodes cassandra2 and cassandra3. Cassandra1 is the master node. and was untainted during our K8S cluster creation lab, however the default schedule should have placed the inital cassandra replicas on nodes not designated as master first. Also the cassandra POD running on node cassandra2 is used in previous steps above as the cqlsh client to load data into cassandra, and is still actively is running the loader, so keep this POD active and running.

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP               NODE
    cassandra-0   1/1       Running   0          2h        10.244.1.55    cassandra3
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2
    
The following steps force a controlled failover that will reschedule the cassandra-0 POD to node cassandra1 as POD cassandra-0. First cordon off cassandra3 from receiving any workloads, as this simulates that cassandra3 is down and not available for any workloads. Then directly fail the cassandra-0 POD on node cassandra3. These actions will force POD cassandra-0 to replicate to the first available node within the K8S cluster which in this case will be cassandra1. Cassandra2 which has a cassandra statefulset POD named cassandra-1, should always remain running as this is where data is being loaded using the cqlsh client. What you should be able to capture using kubectl outputs is the casssandra-0 POD being terminated on node cassandra3 and rescheduling on cassandra1 node and eventually achieving a running state.

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl cordon cassandra3

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl delete pods cassandra-0

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP          NODE
    cassandra-0   1/1       Running   0          4m        10.244.3.89    cassandra1
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2
    
The logs of the cassandra container within cassandra-0 on cassandra1 node can be watched while the cassandra POD recovery is taking place. Within the logs, message references signaling to other cassandra members when nodes are down or up using internally managed SeedProvided IP addresses and log references of commit replays being performed or retried occur during the startup of a POD.  Eventually message entries will be displayed that inform the client endpoints are updated and ready.  Its important to note that when a cassandra POD reaches a running state using the kubectl outputs such as above, it does not imply that recovery has fully occured, but only that the cassandra client has become available for accepting connections.  Even after the cassandra client via the kubectl POD status is announced as ready and available, there are commits and repair processes that are still taking place that need to occur before all cassandra rings should be considered complete replicas with all other cassandra rings and members within the cassandra cluster.  However, reaching a useable active client endpoint status in an automated and reasonably fast timeframe certainly improves RPO metrics, especially when multiple clients are needed when a certain number of clients are needed to remove bottlenecks that might occur when too few clients are available to collect and commit data.

The amount of time it takes to get to a cassandra member to a complete running replica state is another outcome that is available for review and area of possible improvement that PX can provide.  These labs employ a Simplestrategy within a single data center, and a relatively small and static amount of data, therefore do not lend well to being able to demonstrate and produce steps to implement large data set, production grade bootstrapping improvement possibilities offered by using PX.  However its important to introduce and discuss these potential enhancements as they most certainly would be considered for real world, production at scale environments.  

As mentioned in the opening introduction of this repo, Cassandra provides a very robust set of processes and archtiecture that provides a  highly resilient service experience. The first stage of the cassandra recovery process is called bootstrapping and the second stage is called repair.   Bootstrapping is the portion of cassandra recovery that involves the restoration and recovery of committed data that already is stored within the cassandra rings and member replicas.   Repair is the followup process to bootstrapping that syncs any and all uncommited transactions that occurred while a bootstrap was running.   Full recovery times can become a burden when the time to bootstrap takes too long to occur, such as when using a networktopologystrategy and clusters with data is spread across multiple data centers and sync/copy times can be very latent for large data sets during copy operations.  PX provides a snap shot capability that can be employed to occur across all nodes even in a mutidata center configuration.  Using snaps to get to full data set recovery can significantly speed up the bootstrap process by removing the need to copy data across nodes within a multi-region or multi data center cassandra cluster.  Unaddressed latency concerns during bootstrapping cassandra nodes will become even more noticeable and add further negative effects to RTO and RPO as your data sets expand to many petabytes of data that needs to occur during scale or failover events.   It seems inevitable that employing a snap shot solution like PX should be considered. 


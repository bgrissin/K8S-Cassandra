This lab uses local volumes (/var/lib/cassandra) on each host that are created and formatted during the setup steps below.   The local volumes are configured for use within statefulset POD definitions and are deployed as 2 replicas using a headless service named cassandra. 

Scripts are provided for starting, stopping or obtaining status of the cassandra cluster

  1) start-cassandra.sh
  2) stop-cassandra.sh
  3) status-check.sh

On the master K8S node as the kubectl user (joeuser),  change into the cassandra-local directory. You should see several files similar to what is shown below.  

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ ls -l
    total 24
    -rw-rw-r-- 1  joeuser joeuser  165   Sep 11 20:20 cassandra-service.yaml
    -rw-rw-r-- 1  joeuser joeuser 2559   Sep 26 10:14 cassandra-statefulset.yaml
    -rw-rw-r-- 1  joeuser joeuser 1221   Sep 25 19:40 README.md
    -rwxrwxr-x 1  joeuser joeuser   99   Sep 22 10:45 start-cassandra.sh
    -rwxrwxr-x 1  joeuser joeuser  859   Sep 13 22:06 status-check.sh
    -rwxrwxr-x 1  joeuser joeuser  106   Sep 22 10:45 stop-cassandra.sh

Start the cassandra service from here using the start-cassandra.sh script

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ ./start-cassandra.sh

After a few minutes two pods should be up and running, one pod is named cassandra-0 and another called cassandra-1.  Open seperate SSH sessions into both nodes (cassandra2 and cassandra3) where the pods are running.  Also open a second SSH session to each node that can be used for monitoring.

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP          NODE
    cassandra-0   1/1       Running   0          2h        10.244.1.55    cassandra3
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2

One aspect to pay close attention during these next steps for this local volume statefulset to work properly is the way the storage volumes are created and managed for consumption by the cassandra PODs. The cassandra PODS in this lab consume locally mounted and managed volumes that were prepared manually and mounted as /var/lib/cassandra on each host within the K8S cluster setup steps performed earlier.   This 'out of band' approach for creation and management of volumes must align to the definitions specified within cassandra service POD definition, in this case named cassandra-statefulset.yaml.  Keeping proper alignment of volume configurations to service definitions can become quite cumbersome, especially with larger, more expansive production grade environments where the cluster can sprawl and are often  quite distributed.   The next lab (cassandra_PX) uses PX to manage and create the volumes used by services such as the cassandra statefulset POD and thus reveals how PX drastically improves upon the 'out of band' approach of storage management to using a dynamic provisioning approach for creating and managing distributed container storage. 

After connecting via SSH into the cassandra2 host running cassandra,  download some test data to the local volume /var/lib/cassandra.

    root@cassandra2:~/$ curl -o /var/lib/cassandra/raw_weather_data.csv https://raw.githubusercontent.com/killrweather/killrweather-data/master/data/raw_weather_data.csv

Here is a snip of what the file looks like, and there should be approx. 16M of data after the download completes.  Column headers are shown below for reference only, and should not be part of the actual downloaded data. 

    wsid,  year, month, day, hour, temperature, dewpoint, pressure, wind_direction, wind_speed, sky_condition, one_hour_precip, six_hour_precip, twenty_four_hour_precip
    
    725030:14732,2014,  6, 11,  22, 14.4,   0,  1017.6,    0,   0,    ,    18.9,    40,      5.7
    725030:14732,2014,6,11,21,14.4,0,1018.5,0,6,,18.9,40,6.7
    725030:14732,2014,6,11,20,13.9,0,1018.7,0,0,,18.9,40,6.2
    725030:14732,2014,6,11,19,13.9,0,1018.9,0,0,,20,50,5.7
    .
    .
    .
16m of data isn't a very large data set and will load rather quickly into Cassandra.   In order to simulate a longer running load time that can monitor across a longer time interval and also stay running during the time it takes to run a failover simulation test while data is loading, you can make several copies of the 16M file and concatenate (cat file1 file2 ... > raw_weather_data.csv) them together until the size of the raw csv file size reaches approximately 1600GB.   Loading a 160GB will take much longer and provide a longer time interval that performance measurements can be captured on every cassandra node while data is being loaded and a during failover test.

Next, exec into the cassandra container on the cassandra2 K8S node, and see the data file.

    root@cassandra2:~/$ docker ps | grep cass
    9e43b4308340    gcr.io/google-samples/cassandra@sha256:7eed23532e59f9ea03260d161f7554df1f8cc2aae80bfe9e6e027aa1aeb264d0  "/sbin/dumb-     init /bin"   47 seconds ago      Up 47 seconds  k8s_cassandra_cassandra-1_default_07003905-a2f2-11e7-9e00-0cc47ae545ca_0  
    
    root@cassandra2:~/$ docker exec -it 9e43b4308340 bash
    # ls -l /cassandra_data
    total 15644
    -rw-r--r-- 1 root root 1601600539 Sep 26 12:49 raw_weather_data.csv
    
Change your directory to /cassandra_data and run cqlsh from where the data file is located within the container.  

    $ cd /cassandra_data && cqlsh
    
Also within a second seperate SSH session on each host, start iostat against /dev/dm-0 so that we capture IOPS (below captures time interval and TPS every 20 seconds and 100 times) during while data loading and during the failover test.

    $ iostat -mdt /dev/dm-0 20 100 | sed -n -e '1d' -e '/^Device:/d' -e '/^$/d' -e 'p' |sed -e 'N;s/\n/ /' | awk '{ print $2" "$4" - "$5" "$6" "$7; }'

(when testing using px managed volumes in the other lab, this command above changes to monitor the px managed device  /dev/dm-1)

Back to the CQLSH loader screen, execute the following commands to create the keyspaces and tables.

    cqlsh> CREATE KEYSPACE isd_weather_data WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2 };

    cqlsh> use isd_weather_data;

    cqlsh> CREATE TABLE raw_weather_data (wsid text, year int, month int, day int, hour int, temperature double,dewpoint double,pressure double,wind_direction double, wind_speed double, sky_condition text,sky_condition_text text,one_hour_precip double,six_hour_precip double,twenty_four_hour_precip double, PRIMARY KEY ((wsid), year, month, day, hour)) WITH CLUSTERING ORDER BY (year DESC, month DESC, day DESC, hour DESC);
    
Begin the data load process.  This will take some time depending how large the data file is.  Once the loader completes, some details about the load process and statistics will be returned.

    cqlsh> COPY raw_weather_data (wsid, year, month, day, hour, temperature, dewpoint, pressure, wind_direction, wind_speed, sky_condition, one_hour_precip, six_hour_precip,twenty_four_hour_precip) FROM 'raw_weather_data.csv' WITH MAXINSERTERRORS = -1;
        
Let the process of loading data into cassandra run until completion.  You should also have another other SSH session open still that is capturing performance metrics using the iostat command started earlier.  It will be useful to wait at least 10 minutes or more before moving onto the next stages of this lab which initates a controlled and forced failover situation so that a reasonable amount of data reflecting performance metrics are captured prior to and during the failover while data loading is taking place.      

SSH to the K8S master node, and su to the user created for running kubectl (in this lab joeuser is the user, also make certain your admin.conf is sourced).  First check the status of your cassandra PODs.   You should see running cassandra PODs on nodes cassandra2 and cassandra3.   Cassandra1 is the master node. and was untainted during our K8S cluster creation lab, however the default schedule should have placed the inital cassandra replicas on nodes not designated as master first.   Also the cassandra POD running on node cassandra2 is used in previous steps above as the cqlsh client to load data into cassandra, and is still actively is running the loader, so keep this POD active and running.
    
    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP               NODE
    cassandra-0   1/1       Running   0          2h        10.244.1.55    cassandra3
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2
    
The following steps force a controlled failover that will reschedule the cassandra-0 POD to node cassandra1 as POD cassandra-0.   First cordon off cassandra3 from receiving any workloads, as this simulates that cassandra3 is down and not available for any workloads.    Then directly fail the cassandra-0 POD on node cassandra3.   These actions will force POD cassandra-0 to replicate to the first available node within the K8S cluster which in this case will be cassandra1.   Cassandra2 which has a cassandra statefulset POD named cassandra-1, should always remain running as this is where data is being loaded using the cqlsh client.   What you should be able to capture using kubectl outputs is the casssandra-0 POD being terminated on node cassandra3 and rescheduling on cassandra1 node and eventually achieving a running state.   

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl cordon cassandra3
    
    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl delete pods cassandra-0

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP          NODE
    cassandra-0   1/1       Running   0          4m        10.244.3.89    cassandra1
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2

The amount of time it takes to get to a running state as a new POD on cassandra1 node is another outcome that is available for review.  As mentioned in the opening introductions in this repo, Cassandra provides a very robust process for recovery, and does so in a two stage process.  The first stage of the recovery process is called bootstrapping and the second stage is called repair.   You can watch the logs of the cassandra container within the cassandra-0 POD on cassandra1 while these steps are taking place.  Its important to note that when a cassandra POD reaches a running state using the kubectl outputs such as above, does not indicate that recovery has fully occured, but only that the cassandra client has become available for accepting connections.  

During the bootstrap phase of the recovery, you will find in the logs, message references that signal to other cassandra members when nodes are down or up using internally managed IP addresses.  Also you will find log references of commit replays are being performed.  

This concludes the local storage version of this lab, please more forward to the next step [here](https://github.com/bgrissin/K8S-Cassandra/blob/master/cassandra-px/README.md)


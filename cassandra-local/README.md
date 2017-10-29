This lab makes use of local volumes (/var/lib/cassandra) on each host that were created and formatted during the setup of the K8S cluster nodes.   Local volumes are configured within a statefulset POD that are deployed as 2 replicas with a headless service called cassandra.  

Scripts are provided for starting, stopping or obtaining status of the cassandra cluster

  1) start-cassandra.sh
  2) stop-cassandra.sh
  3) status-check.sh

On the master node as the user configured for use with kubectl,  cd into the cassandra-local directory. You should see several files similar to what is shown below.  

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

After a few minutes two pods should be up and running cassandra, one pod is named cassandra-0 and another called cassandra-1.  Open seperate SSH sessions into both nodes (cassandra2 and cassandra3) where the pods are running.  Also open a second SSH session to each node that we can use to setup for monitoring purposes

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP          NODE
    cassandra-0   1/1       Running   0          2h        10.244.1.55    cassandra3
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2

One aspect to pay close attention during the following steps taken for this local volume statefulset to work properly is the way storage volumes are created and managed.  For the cassandra PODS in this lab that consume locally mounted and managed volumes to work, the volumes must have already been prepared manually and mounted as /var/lib/cassandra on each host within the K8S cluster.   This 'out of band' approach for creation and management of volumes must align to the definitions within the service definitions.  Keeping proper alignment of the volume configurations to the cassandra service can become quite cumbersome, especially in larger production grade environments.   The next lab (cassandra_PX) uses PX to manage and create the volumes used by the cassandra services and reveals how PX drastically improves from the 'out of band' approach of storage management to use a dynamic provisioning approach that automatically keeps track of the 

Using one of the SSH sessions into cassandra2 host running cassandra,  download some test data to our local volume /var/lib/cassandra that we can use to load directly into cassandra

    root@cassandra2:~/$ curl -o /var/lib/cassandra/raw_weather_data.csv https://raw.githubusercontent.com/killrweather/killrweather-data/master/data/raw_weather_data.csv

Here is a snip of what the file looks like, and there is approx. 16M of data in the download.  I have added column headers as well 

    wsid,  year, month, day, hour, temperature, dewpoint, pressure, wind_direction, wind_speed, sky_condition, one_hour_precip, six_hour_precip, twenty_four_hour_precip
    725030:14732,2014,  6, 11,  22, 14.4,   0,  1017.6,    0,   0,    ,    18.9,    40,      5.7
    725030:14732,2014,6,11,21,14.4,0,1018.5,0,6,,18.9,40,6.7
    725030:14732,2014,6,11,20,13.9,0,1018.7,0,0,,18.9,40,6.2
    725030:14732,2014,6,11,19,13.9,0,1018.9,0,0,,20,50,5.7
    .
    .
    .
16m of data isn't a very large data set and will load rather quickly into Cassandra.   In order to simulate a longer running load time that can monitor across a longer time interval and also stay running during a failover simulation test while data is loading, you can make several copies of the 16M file and concatenate (cat file1 file2 ... > raw_weather_data.csv) them together until the size of the raw csv file size reaches approximately 1600GB.   Loading a 160GB will take much longer and provide a longer time interval that performance measurements can be captured on every cassandra node while data is being loaded and a during failover test.

Next, exec into the cassandra container on the cassandra2 K8S node, and see the data file.

    root@cassandra2:~/$ docker ps | grep cass
    9e43b4308340    gcr.io/google-samples/cassandra@sha256:7eed23532e59f9ea03260d161f7554df1f8cc2aae80bfe9e6e027aa1aeb264d0  "/sbin/dumb-     init /bin"   47 seconds ago      Up 47 seconds  k8s_cassandra_cassandra-1_default_07003905-a2f2-11e7-9e00-0cc47ae545ca_0  
    
    root@cassandra2:~/$ docker exec -it 9e43b4308340 bash
    # ls -l /cassandra_data
    total 15644
    -rw-r--r-- 1 root root 1601600539 Sep 26 12:49 raw_weather_data.csv

Run cqlsh from within the container.  You should also change your directory to /cassandra_data where you placed the data file.  

    $ cd /cassandra_data && cqlsh
    
Also within a second seperate SSH session on each host, start an iostat against /dev/dm-0 so that we capture IOPS (below captures time interval and TPS evey 20 seconds and 100 times) during our data loading

    $ iostat -mdt /dev/dm-0 20 100 | sed -n -e '1d' -e '/^Device:/d' -e '/^$/d' -e 'p' |sed -e 'N;s/\n/ /' | awk '{ print $2" "$4" - "$5" "$6" "$7; }'

(when testing using px managed volumes in the other lab, this command above changes to monitor the px managed device  /dev/dm-1)

Back to the CQLSH loader screen, execute the following commands to create the keyspaces and tables.

    cqlsh> CREATE KEYSPACE isd_weather_data WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2 };

    cqlsh> use isd_weather_data;

    cqlsh> CREATE TABLE raw_weather_data (wsid text, year int, month int, day int, hour int, temperature double,dewpoint double,pressure double,wind_direction double, wind_speed double, sky_condition text,sky_condition_text text,one_hour_precip double,six_hour_precip double,twenty_four_hour_precip double, PRIMARY KEY ((wsid), year, month, day, hour)) WITH CLUSTERING ORDER BY (year DESC, month DESC, day DESC, hour DESC);
    
Begin the data load process.  This will take some time depending how large you made you data file.  Once your loader completes you should receive some details about the load process and statistics.

    cqlsh> COPY raw_weather_data (wsid, year, month, day, hour, temperature, dewpoint, pressure, wind_direction, wind_speed, sky_condition, one_hour_precip, six_hour_precip,twenty_four_hour_precip) FROM 'raw_weather_data.csv' WITH MAXINSERTERRORS = -1;
        
At this point you should be successfully loading data into cassandra and capturing some performance metrics while the data loader was taking place.   Rather than stop the iostat monitor and the loader, capture the current time and date on each node and then continue on to the next steps create a forced failover scenario. 

SSH to the K8S master node, and su to the user created for running kubectl.  First check the status of your cassandra PODs.   You should see running cassandra PODs on nodes cassandra2 and cassandra3.   Cassandra1 is the master node. and was untainted during our K8S cluster creation lab, however the default schedule should have placed the inital cassandra replicas (2) on nodes not designated as master first.   Also the cassandra POD running on node cassandra2 was used in previous steps above as the cqlsh client to load data into cassandra, and is still actively is running the loader, so keep this POD active and running.
    
    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP               NODE
    cassandra-0   1/1       Running   0          2h        10.244.1.55    cassandra3
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2
    

The following steps force a controlled fail over that will reschedule a failed cassandra POD to a node that is not being used.   In this case we are going to fail the cassandra POD on the node cassandra3 and the POD name is cassandra-0.   To force this POD to another available node within the K8S cluster, first cordon off cassandra3 from receiving any workloads.  What you should see is the casssandra POD eventually rescheduling the POD cassandra-0 to run on the node cassandra1.  Cassandra2 which also has a cassandra statefulset POD named cassandra-1, but that is where data is being loaded using the cqlsh client and want to keep that running.  

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl cordon cassandra3
    
    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl delete pods cassandra-0

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP          NODE
    cassandra-0   1/1       Running   0          4m        10.244.3.89    cassandra1
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2



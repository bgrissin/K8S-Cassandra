For this lab we use local volumes (/var/lib/cassandra) on each host that were created and formatted when we setup our K8S cluster nodes.

These local volumes are consumed by cassandra stateful PODs that are deployed via a K8S statefulset service using a headless service called cassandra.  Each Cassandra POD is also configured for Cassandra to use 2 replicas.  

To start stop or get the status ofthe PODs or the status of the cassandra cluster using nodetool are scripted into three different scripts

  1) start-cassandra.sh
  2) stop-cassandra.sh
  3) status-check.sh

On the master node, within the git repo cloned earlier, cd into the cassandra-local directory. You should see several files similar to what is shown below.  

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ ls -l
    total 24
    -rw-rw-r-- 1   joeuser joeuser  165   Sep 11 20:20 cassandra-service.yaml
    -rw-rw-r-- 1   joeuser joeuser 2559  Sep 26 10:14 cassandra-statefulset.yaml
    -rw-rw-r-- 1   joeuser joeuser 1221  Sep 25 19:40 README.md
    -rwxrwxr-x 1 joeuser joeuser   99    Sep 22 10:45 start-cassandra.sh
    -rwxrwxr-x 1 joeuser joeuser  859   Sep 13 22:06 status-check.sh
    -rwxrwxr-x 1 joeuser joeuser  106   Sep 22 10:45 stop-cassandra.sh

You should be able to start cassandra from here using the start-cassandra.sh script

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ ./start-cassandra.sh

After a few minutes should have two pods running cassandra, one pod is named cassandra-0 and another called cassandra-1.  Open seperate SSH sessions into both nodes (cassandra2 and cassandra3) where the pods are running.  Also open a second SSH session to each node that we can use to setup for monitoring purposes

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP          NODE
    cassandra-0   1/1       Running   0          2h        10.244.1.55     cassandra3
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2

This statefulset makes use of the local volumes that were created during the K8S create steps performed earlier.  The volumes align to the statefulset volume parameters and definitions that exist within the Cassandra statefulset defintion file called cassandra-statefulset.yaml.  

One aspect to pay close attention to for these next steps are the volumes needed for this statefulset to work in this lab setting properly. The volumes must have already been created manually across all hosts when we created the K8S cluster.  Its important to note these local volumes must exist and be prepared for use with a proper partition and file systems, else any scale up or failover to a node that does not have the proper volume setups will create failures and issues.   These steps in this lab setting drastically differ from the other lab using PX created and managed.    devices.   

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
16m of data isnt a very large data set and I wanted to simulate a longer running load time so that I could monitor across a longer time interval and also run a failover simulation test while data is loading.   I made several copies of the 16M file and concatenated (cat file1 file2 ... > raw_weather_data.csv) together until I had a raw csv file size of approximately 500GB.   Loading a 500GB will take much longer and give me a longer time interval that I can measure performance on every cassandra node while the data is being loaded and a failover test can be executed as well

Next, exec into the cassandra container, and make certain you see the data file

    root@cassandra2:~/$ docker exec -it 9e43b4308340 bash
    # ls -l /cassandra_data
    total 15644
    -rw-r--r-- 1 root root 1601600539 Sep 26 12:49 raw_weather_data.csv

Run cqlsh from within the container.  You should also change your directory to /root first or where you placed the data file.  

    $ cqlsh
    
Also in a second SSH session for each host, start an iostat for /dev/dm-0 so that we capture IOPS (below captures time interval and TPS evey 20 seconds and 100 times) during our data loading

    $ iostat -mdt /dev/dm-0 20 1000 | sed -n -e '1d' -e '/^Device:/d' -e '/^$/d' -e 'p' |sed -e 'N;s/\n/ /' | awk '{ print $2" "$4" - "$5" "$6" "$7; }'

(when testing using px managed volumes in the other lab, this command above changes to monitor the px managed device  /dev/dm-1)

Back to the CQLSH loader screen, execute the following commands to create the keyspaces and tables.

    cqlsh> CREATE KEYSPACE isd_weather_data WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2 };

    cqlsh> use isd_weather_data;

    cqlsh> CREATE TABLE raw_weather_data (wsid text, year int, month int, day int, hour int, temperature double,dewpoint double,pressure double,wind_direction double, wind_speed double, sky_condition text,sky_condition_text text,one_hour_precip double,six_hour_precip double,twenty_four_hour_precip double, PRIMARY KEY ((wsid), year, month, day, hour)) WITH CLUSTERING ORDER BY (year DESC, month DESC, day DESC, hour DESC);
    
Begin the data load process.  Depending on the size of your data file, this can be quite lengthy.   Once your loader completes you should receive some details about the load process and statistics.

    cqlsh> COPY raw_weather_data (wsid, year, month, day, hour, temperature, dewpoint, pressure, wind_direction, wind_speed, sky_condition, one_hour_precip, six_hour_precip,twenty_four_hour_precip) FROM 'raw_weather_data.csv' WITH MAXINSERTERRORS = -1;
        
At this point you should be successfully loading data into cassandra and capturing some performance metrics while the data loader was taking place.   Rather than stop the iostat monitor and the loader, capture the current time and then continue on to the next steps below that monitors IOPS during a forced failover scenario. 

SSH to you K8S master node, and su to the user that you created for running kubectl (in the examples provided earlier in these labs the user was 'joeuser').   Using the commands provided below, check for the status of your cassandra PODs and your K8S nodes.  Using these two commands will tell you what cassandra pods are running on which nodes.  Cassandra1 is the master node, and cassandra2 and 3 are the nodes that are workers are are running two replicas of Cassandra statefulsets. Also the cassandra service on node cassandra2 was used as the cqlsh client to load data into cassandra, and is still actively is running the loader, so keep this POD active and running.

$ kubectl get pods -o wide
$ kubectl get nodes

We want a forced and controlled failure that reschedules the cassandra replica node that is not being used as a cassandra client for loading data, and in this case that node is cassandra3 and the POD name is cassandra-02.   To force this POD to another available node within the K8S cluster, first cordon off cassandra3 from receiving ant workloads.   Next delete POD cassandra-02, which in effect is the failure.   When setting up the K8S cluster earlier, we untainted our master node, cassandra1, thus allowing for the master to accept schedule requests to run workloads. What you should see is the casssandra POD eventually rescheduling the POD cassandra-02 to run on the node cassandra1.  Cassandra2 also has a statefulset cassandra POD named cassandra-01, but that is where I am loading data using the cqlsh client and I want to keep that running.  

$ Kubectl cordon cassandra3

$ kubectl get pods -o wide











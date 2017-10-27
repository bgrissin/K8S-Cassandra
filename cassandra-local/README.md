For this test we use existing volumes (/var/lib/cassandra/data) on each host that are created and formatted when we setup our K8S cluster nodes.

These local volumes are consumed by cassandra stateful PODs that are deployed via a K8S statefulset service using a headless service called cassandra.  Each Cassandra POD is also configured for Cassandra to use 2 replicas.  

To start stop or get the status ofthe PODs or the status of the cassandra cluster using nodetool are scripted into three different scripts

  1) start-cassandra.sh
  2) stop-cassandra.sh
  3) status-check.sh

PX performance monitoring and failover

On the master node,  from within the git repo you cloned earlier, cd into the cassandra-local directory. You should see several scripts and files similar to what is shown below.  

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

After a few minutes should have two pods running cassandra, one pod is named cassandra-0 and another called cassandra-1.  SSH into both nodes (cassandra2 and cassandra3) where the pods are running.  Also while your at it, open a second SSH session to each node that we can use to setup for monitoring purposes

    joeuser@cassandra1:~/K8S-Cassandra/cassandra-local$ kubectl get pods -o wide
    NAME          READY     STATUS    RESTARTS   AGE       IP          NODE
    cassandra-0   1/1       Running   0          2h        10.244.1.55     cassandra3
    cassandra-1   1/1       Running   0          2h        10.244.2.131   cassandra2

unlike when using the PX volumes, this statefulset does not make use of persistant claims and persistant volumes that PX dynamically creates upon request.  Instead this statefulset makes use of volumes that are preconfigured out of band to align to the statefulset parameters needed for any Cassandra POD that may be started on each host.

Choose from one of the 2 hosts running cassandra (NODE cassandra2 or 3) and lets download some test data that we can use to load into cassandra

    root@cassandra2:~/$ curl -o raw_weather_data.csv https://raw.githubusercontent.com/killrweather/killrweather-data/master/data/raw_weather_data.csv

Here is a snip of what the file looks like, and there is approx. 16M of data in the download.  I have added column headers as well 

    wsid,               year,       month,   day, hour, temperature, dewpoint, pressure, wind_direction, wind_speed, sky_condition, one_hour_precip, six_hour_precip, twenty_four_hour_precip
    725030:14732,2014,          6,      11,      22,      14.4,              0,          1017.6,            0,                       0,                    ,                     18.9,                     40,                     5.7
    725030:14732,2014,6,11,21,14.4,0,1018.5,0,6,,18.9,40,6.7
    725030:14732,2014,6,11,20,13.9,0,1018.7,0,0,,18.9,40,6.2
    725030:14732,2014,6,11,19,13.9,0,1018.9,0,0,,20,50,5.7
    .
    .
    .

Now lets find the cassandra container ID for cassandra on the host your currently ssh'd into

    root@cassandra2:~/$ docker ps | grep cass

    9e43b4308340        gcr.io/google-samples/cassandra@sha256:7eed23532e59f9ea03260d161f7554df1f8cc2aae80bfe9e6e027aa1aeb264d0             "/sbin/dumb-init /bin"   2 hours ago         Up 2 hours                                                                                                            k8s_cassandra_cassandra-1_default_eef4e60f-a2a3-11e7-9e00-0cc47ae545ca_0

The container ID is what we need so we can gain access into the container. In my example above my container ID is 9e43b4308340
Lets get the sample data into the cassandra docker container that we curl'd earlier.

    root@cassandra2:~/$  docker cp raw_weather_data.csv 9e43b4308340:/root/raw_weather_data.csv

Next lets exec into that container, and make certain you see the data file

    root@cassandra2:~/$ docker exec -it 9e43b4308340 bash
    # ls -l
    total 15644
    -rw-r--r-- 1 root root 16015396 Sep 26 12:49 raw_weather_data.csv

Now lets run cqlsh and begin import data into cassandra from this host.  Also in a second SSH session for each host, lets begin an iostat that we capture what is going on during our data loading

    $ cqlsh

    $ iostat -mxdt /dev/dm-0 20 100 | sed -n -e '1d' -e '/^Device:/d' -e '/^$/d' -e 'p' |sed -e 'N;s/\n/ /' | awk '{ print $4" - "$1" "$2" "$7" "$8" "$12" "$13" "$16" "$17; }'

(for testing px volumes this command would change to monitor the px dev i.e. /dev/dm-1)


    cqlsh> CREATE KEYSPACE isd_weather_data WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2 };

    cqlsh> use isd_weather_data;

    cqlsh> CREATE TABLE raw_weather_data (wsid text, year int, month int, day int, hour int, temperature double,dewpoint double,pressure double,wind_direction double, wind_speed double, sky_condition text,sky_condition_text text,one_hour_precip double,six_hour_precip double,twenty_four_hour_precip double, PRIMARY KEY ((wsid), year, month, day, hour)) WITH CLUSTERING ORDER BY (year DESC, month DESC, day DESC, hour DESC);

    cqlsh> COPY raw_weather_data (wsid, year, month, day, hour, temperature, dewpoint, pressure, wind_direction, wind_speed, sky_condition, one_hour_precip, six_hour_precip,twenty_four_hour_precip) FROM 'raw_weather_data.csv' WITH MAXINSERTERRORS = -1;

    cqlsh> quit

    root@cassandra2:~/$ nodetool getendpoints isd_weather_data raw_weather_data  725030

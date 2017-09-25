First, log into Packet.net and create three type0 instances, and name them cassandra1, cassandra2 and cassandra3. 

Then create 6 volumes and attach a pair of volumes to each host instance. You can also name the volume pairs individually if you want. on each host instance, one of the volumes will be a local mounted and managed volume and the other will be a PX managed volume.

Next test your connection by using SSH to login to the first cassandra instance (cassandra1) and clone this repo. 

Also verify you can ssh to the other instances (cassandra2 and cassandra3)

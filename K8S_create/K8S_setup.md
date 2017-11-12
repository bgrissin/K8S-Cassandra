# K8S cluster setup details

The link below was used as the primary reference for setting up a three node K8S cluster.  

	https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/

## Get some Infrastructure

This lab can be run on most public or private platforms.   Packet.net was chosen as the platform for these labs because of the close resemblance to an on premises experience.

First, log into Packet.net and create three type0 instances, and name them cassandra1, cassandra2 and cassandra3.   Also create 6 volumes and attach a pair of volumes to each host instance.  For each host instance, one of the volumes will act as a locally mounted volume and the other will be a PX managed volume.  Once two volumes are attached to each instance, the setup for those volumes is covered in section below titled 'Create a K8S cluster'

Initiate and test SSH sessions into the first cassandra instance (cassandra1) and clone this repo.  Also initiate ssh sessions to the other instances (cassandra2 and cassandra3)

## Begin to install and configure a K8S cluster

Perform the following steps provided below on all 3 nodes as root to prepare for installation of a K8S cluster.  

    #  apt-get update && apt-get install -qy docker.io
    #  apt-get update && apt-get install -y apt-transport-https
    #  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    #  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
    #  apt-get update
    #  apt-get install -y kubelet kubeadm kubernetes-cni
    
Packet hosts use bond0 for public IP, bond0:0 for private IP.  You should almost always choose to use private addresses for cluster wide intra-communications

SSH to the first node (from here on out will be referred to as the master node) and use ifconfig to capture the private IP of the bond0:0 interface.  
    
    # ifconfig bond0:0
          bond0:0   Link encap:Ethernet  HWaddr 0c:c4:7a:e5:45:ca
          inet addr:10.100.1.3  Bcast:255.255.255.255  Mask:255.255.255.254
          UP BROADCAST RUNNING MASTER MULTICAST  MTU:1500  Metric:1
                 
Init the K8S cluster on the master node. This lab make use of the Flannel network plugin, so add in the appropriate CIDR range required for settting up Flannel and be sure to use the private IP address collected from the previous ifconfig step to instruct where to run the K8S API server.  You should capture the information at the end of the successful init output so that you can add additional nodes to the K8S cluster.
    
    #  kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.100.1.3 
    
Next, SSH to both nodes 2 and 3, execute the join statement captured from the previous step as the root user.  The IP address should be the private IP address for bond0:0 of the master node captured in the previous ifconfig statement

    #  kubeadm join --token c157b5.92eba9c3d6ac5c17 10.100.1.3:6443
  
These following steps should be performed on all 3 nodes.  
    
    #  useradd joeuser -G sudo -m -s /bin/bash 
    #  passwd joeuser
    #  sudo usermod -aG docker joeuser
    #  su - joeuser
    #  docker ps  ----> make certain docker runs as user joeuser
        
These steps are optional for nodes 2 and 3, but must be done on the master node (node 1).  In the example provided below, joeuser is the user being created and sourced with the capabilities for running kubectl, which will be necessary to keep in mind during the labs coming up.
     
    #  su - joeuser
    #  sudo cp /etc/kubernetes/admin.conf $HOME/
    #  sudo chown $(id -u):$(id -g) $HOME/admin.conf
    #  export KUBECONFIG=$HOME/admin.conf
    
Once you have completed these steps successfully, you should be able to see your K8S cluster nodes and verify the services you need are  running.  Note that the kube-dns pod should be in a pending state until after you add the pod networking solution, this lab uses flannel.  Also, run kubectl as the user you setup (i.e. joeuser), not as root.  Also consider updating your shell profile with the admin.conf export so you do not have to keep sourcing the env variables.

	 #  kubectl get nodes
		
			NAME         STATUS    AGE       VERSION
			cassandra1   Ready     1d        v1.7.5
			cassandra2   Ready     1d        v1.7.5
			cassandra3   Ready     1d        v1.7.5
			
	  # kubectl get all --namespace=kube-system
			NAME                                    READY     STATUS    RESTARTS  
			po/etcd-cassandra1                      1/1       Running   1         
			po/kube-apiserver-cassandra1            1/1       Running   1         
			po/kube-controller-manager-cassandra1   1/1       Running   1          
			po/kube-dns-2425271678-zz2mx            1/1       Pending   0          
			po/kube-proxy-ntqtl                     1/1       Running   1          
			po/kube-scheduler-cassandra1            1/1       Running   1          

			NAME                   CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
			svc/kube-dns           10.96.0.10     <none>        53/UDP,53/TCP   1m
			
			NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
			deploy/kube-dns   1         1         1            0           1m
			
			NAME                     DESIRED   CURRENT   READY     AGE
			rs/kube-dns-2425271678   1         1         0         1m
			
When a DNS pending state is noticed, apply the flannel networking services that will allow PODs to communicate to each other across the entire cluster.  
 
	 #  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
	 #  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel-rbac.yml
	 
You should now be able to see proxy and flannel services are starting and you should be able to see that DNS is in a running state
	 
	 #  kubectl get all --namespace=kube-system
	 
			NAME                                    READY     STATUS    RESTARTS   
			po/etcd-cassandra1                      1/1       Running   1          
			po/kube-apiserver-cassandra1            1/1       Running   1          
			po/kube-controller-manager-cassandra1   1/1       Running   1          
			po/kube-dns-2425271678-zz2mx            3/3       Running   3          
			po/kube-flannel-ds-3krds                2/2       Running   1         
			po/kube-flannel-ds-djsgw                2/2       Running   1          
			po/kube-flannel-ds-nkb28                2/2       Running   1          
			po/kube-proxy-ntqtl                     1/1       Running   1          
			po/kube-proxy-tv1qs                     1/1       Running   1          
			po/kube-proxy-wx9rk                     1/1       Running   1          			
			po/kube-scheduler-cassandra1            1/1       Running   1          
			
			NAME                   CLUSTER-IP     EXTERNAL-IP   PORT(S)         
			svc/kube-dns           10.96.0.10     <none>        53/UDP,53/TCP        
			
			NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   
			deploy/kube-dns   1         1         1            1           
			
			NAME                     DESIRED   CURRENT   READY    
			rs/kube-dns-2425271678   1         1         1         
			
Also the default K8S config does not allow you to deploy pods on your master, for this lab we want to unset this restriction by running the following command.			
	
	 #  kubectl taint nodes --all node-role.kubernetes.io/master-
	 
## Configuring local storage. 

Packet hosts allow you to attach mulitple storage volumes to your each of your instances.  For this lab each node has two seperate volumes presented per node (one volume for use with PX and the other as a locally mounted volume as /var/lib/cassandra).  They should appear as dm-0 and dm-1 as in the output shown below (run these steps as root, and perform these steps on each packet host).

    # root@cassandra1:~# packet-block-storage-attach -m queue
    
If successful, you should be able to see each of the new storage devices using the multipath tools on each packet host

    #  root@cassandra1:~# multipath -ll
     
        volume-ab51ff46 (36001405bef83ee4e75b44a295d1f6398) dm-0 DATERA,IBLOCK
        size=100G features='1 queue_if_no_path' hwhandler='1 alua' wp=rw
        `-+- policy='round-robin 0' prio=1 status=active
          |- 3:0:0:0 sde 8:64 active ready running
          `- 2:0:0:0 sdb 8:16 active ready running
        volume-d9bc26f9 (36001405b749edc435474992a28cd2563) dm-1 DATERA,IBLOCK
        size=100G features='1 queue_if_no_path' hwhandler='1 alua' wp=rw
        `-+- policy='round-robin 0' prio=1 status=active
          |- 5:0:0:0 sdd 8:48 active ready running
          `- 4:0:0:0 sdc 8:32 active ready running
 
Use dm-0 on all 3 host instances as the locally mounted volume /var/lib/cassandra on each host and dm-1 will be used later as the PX managed volume on each host.  Create a disk partition on each dm-0 device on each host.
    
    # fdisk /dev/dm-0
      - press n to create a new partition
      - select p for primary
      - Press enter to select default partition size and partition number.  
      - Enter a 'w' to write the partition information 
      - Copy the device volume name, it will be needed a few steps later 
             Device                            Boot Start       End   Sectors  				Size Id Type
	/dev/mapper/volume-ab51ff46-part1       2048 209715199 209713152  100G 83 Linu
      - Then press 'q' to quit fdisk.

Now use kpartx to write the new device info into the kernel, or just reboot the host, In the example below opts to not reboot and use the kpartx instead
    
    #  kpartx -u /dev/mapper/volume-ab51ff46-part1 
    
Next place a File System on the new volume and then mount it for use in the first lab called cassandra-local
    
    #  mkfs.ext4 /dev/mapper/volume-ab51ff46-part1 
    
    #  mkdir /var/lib/cassandra
    
    #  mount /dev/mapper/volume-ab51ff46-part1 /var/lib/cassandra/
    
## Configure PX Storage

The last step we need to do to complete our K8S cluster is to install PX.   This release of PX requires a keystore DB such as etcd or consul.  For this lab it was decided use an etcd. Etcd can be setup to run locally as a single instance, or a cluster, and can even be setup to run remotely as a service.  For this lab, etcd is setup to run as a container on the master K8S node and on specific ports that dont conflict with ports being used by the K8S KV.  Portworx does not recommend using the existing K8S Keystore for running PX.  There is an upcoming release of PX that will come with its own builtin KV, thus removing the need to install etcd or consul.  Please follow the portworx website to stay up to date when the built in kv option will be available.

First collect the private IP on the K8S master node bond0:0 interface and export the IP into a variable as follows:

    #  ifconfig bond0:0
          bond0:0   Link encap:Ethernet  HWaddr 0c:c4:7a:e5:45:ca
          inet addr:10.100.1.3  Bcast:255.255.255.255  Mask:255.255.255.254
          UP BROADCAST RUNNING MASTER MULTICAST  MTU:1500  Metric:1
    
    #  IPADDR=10.100.1.3
    
    # docker run -d -p 14001:14001 -p 12379:12379 -p 12380:12380 \
     --restart=always \
     --name etcd-px quay.io/coreos/etcd:v2.3.8 \                              
     -name etcd0 \                                                            
     -data-dir /var/lib/etcd/ \                                               
     -advertise-client-urls http://${IPADDR}:12379,http://${IPADDR}:14001 \   
     -listen-client-urls http://0.0.0.0:12379 \
     -initial-advertise-peer-urls http://${IPADDR}:12380 \
     -listen-peer-urls http://0.0.0.0:12380 \
     -initial-cluster-token etcd-cluster \
     -initial-cluster etcd0=http://${IPADDR}:12380 \
     -initial-cluster-state new

Next, install PX to use dynamic provisioning from your master node.  You have two paths you can take to prepare your PX service.  
	
1) you can directly edit the provided px-spec.yaml in the cassandra-px/StorageClass directory of this repo [here](https://github.com/bgrissin/K8S-Cassandra/blob/master/cassandra-px/StorageClass/px-spec.yaml)
2) or you can create your own px-spec.yaml using the curl syntax provided below and copy into the cassandra-px/StorageClass directory 
	
In either case be sure to change the etcd IP address(es) and ports that are required to match what private IP(s) and port combination you decided to use for your etcd service performed during the K8S setup steps done previously.
	
     # curl -o px-spec.yaml "http://install.portworx.com?cluster=my-px-cluster&kvdb=etcd://10.100.1.3:12379&drives=/dev/dm-1&diface=bond0:0&miface=bond0&master=true"
	
Once you have your px-spec.yaml created, you then should be able to create the PX service using the following command from where you created the px-spec.yaml.  Remember to login or su to the kubectl user (joeuser) setup earlier in order to run this command.

     # kubectl apply -f px-spec.yaml
	 
After a few minutes, you should be able to run PXCTL on any node in your cluster at this point.
     
     # /opt/pwx/bin/pxctl status
	 
This concludes the steps for setting up your K8S cluster.  Please move forward to the next stage of this lab [here](https://github.com/bgrissin/K8S-Cassandra/blob/master/cassandra-local/README.md)

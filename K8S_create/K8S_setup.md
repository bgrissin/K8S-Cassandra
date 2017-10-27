# K8S cluster setup details

I used this link as my reference for setting up my three node K8S cluster.  

	https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/

Perform these steps to prepare and install K8S on all 3 nodes, all as root user on each node.

    #  apt-get update && apt-get install -qy docker.io
    #  apt-get update && apt-get install -y apt-transport-https
    #  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    #  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
    #  apt-get update
    #  apt-get install -y kubelet kubeadm kubernetes-cni
    
Packet hosts use bond0 for public IP, bond0:0 for private IP.  You should always choose to use private addresses for cluster wide intra-communications

SSH to the first node (from here on out will be referred to as the master node) and use ifconfig to capture the private IP of the bond0:0 interface.  
    
    # ifconfig bond0:0
          bond0:0   Link encap:Ethernet  HWaddr 0c:c4:7a:e5:45:ca
          inet addr:10.100.1.3  Bcast:255.255.255.255  Mask:255.255.255.254
          UP BROADCAST RUNNING MASTER MULTICAST  MTU:1500  Metric:1
                 
Init the K8S cluster on the master node. We're use Flannel networking so add in the appropriate CIDR range for Flannel and specify the private IP address collected from the previous ifconfig step to instruct where to run the K8S API server.  You should capture the information at the end of the successful init output so that you can add additional nodes to the K8S cluster.
    
    #  kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.100.1.3 
    
Next, SSH to both nodes 2 and 3, execute the join statement captured from the previous step as the root user.  The IP address should be the private IP address for bond0:0 of the master node captured in the previous ifconfig statement

    #  kubeadm join --token c157b5.92eba9c3d6ac5c17 10.100.1.3:6443
  
These following steps should be performed on all 3 nodes.  
    
    #  useradd joeuser -G sudo -m -s /bin/bash 
    #  passwd joeuser
    #  sudo usermod -aG docker joeuser
    #  su - joeuser
    #  docker ps  ----> make certain docker runs as user joeuser
        
These steps are optional for nodes 2 and 3, but must be done on the master node (node 1).  In this case, joeuser is the user.
     
    #  su - joeuser
    #  sudo cp /etc/kubernetes/admin.conf $HOME/
    #  sudo chown $(id -u):$(id -g) $HOME/admin.conf
    #  export KUBECONFIG=$HOME/admin.conf
    
Once you have completed these steps successfully, you should be able to see your K8S cluster nodes and verify that the services you need to have running.  Note that the kube-dns pod should be in a pending state until after you add the pod networking solution.  In this lab we are planning to use flannel.  Note that from here on out, your running kubectl as the user you setup, not as root.  You may want to add in the admin.conf export to your profile so you do not have to keep sourcing the env variables.

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
			
When I receive a DNS pending state, apply the flannel networking services that will allow PODs to communicate to each other across the entire cluster.  
 
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

Packet hosts allow you to attach mulitple storage volumes to your each of your instances.  For this lab each node has two seperate volumes presented per node (one volume for use with PX and the other as a locally mounted volume as /var/lib/cassandra).  They should appear as dm-0 and dm-1 as in the output shown below (run these steps as root)

    # packet-block-storage-attach -m queue
    
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

We then have to use kpartx to write the new device info into the kernel. We could also just reboot the host, but we are going to save the reboot and use the kpartx instead
    
    #  kpartx -u /dev/mapper/volume-ab51ff46-part1 
    
Next place a File System on the new volume and then mount it for use in the first lab called cassandra-local
    
    #  mkfs.ext4 /dev/mapper/volume-ab51ff46-part1 
    
    #  mkdir /var/lib/cassandra
    
    #  mount /dev/mapper/volume-ab51ff46-part1 /var/lib/cassandra/
    
## Configure PX Storage

The last step we need to do to complete our K8S cluster is to install PX.   To install PX we need to setup a keystore DB such as etcd or consul.  For this lab we decided use an etcd cluster (multiple etcd containers) running as containers on each K8S node and on specific ports that dont conflict with ports being used by the K8S KV.  Portworx does not recommend using the existing K8S Keystore for running PX.  There is an upcoming release of PX that will come with its own KV within, thus removing the need to install etcd or consul.

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

Next we are going to install dynamic provisioning PX from your master node.  You have two paths you can take to prepare your PX service.  
	
	1) you can directly edit the provided px-spec.yaml in the cassandra-px/StorageClass directory of this repo, or
	2) you can create your own px-spec.yaml using the curl syntax provided below.  
	
In both cases you should only have to change the etcd IP address to match what private IP you used for setting up your etcd.
	
     #curl -o px-spec.yaml "http://install.portworx.com?cluster=my-px-cluster&kvdb=etcd://10.100.1.3:12379&drives=/dev/dm-1&diface=bond0:0&miface=bond0&master=true"
	
Once you have your px-spec.yaml created, you then should be able to create the dynamic provisioning PX service using the following command from where you created the px-spec.yaml

     # kubectl apply -f px-spec.yaml
	 
After a few minutes, you should be able to run PXCTL on any node in your cluster at this point.
     
     # /opt/pwx/bin/pxctl status
	 
This concludes the steps for setting up your K8S cluster for use with this lab.  Please move forward to the next stage of the lab.

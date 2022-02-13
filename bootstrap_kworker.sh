#!/bin/bash

IP_ADDRESS=`ip addr | grep eth1 | grep inet | awk '{print $2}' | awk -F '/' '{print $1}'`

echo "[TASK 1] Join node to K3s Cluster"
apt install -qq -y sshpass >/dev/null 2>&1
sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no k3s1:/root/joincluster.sh /root/joincluster.sh 2>/dev/null
sed -i 's/0.0.0.0/'${IP_ADDRESS}'/' /root/joincluster.sh
bash /root/joincluster.sh >/dev/null 2>&1
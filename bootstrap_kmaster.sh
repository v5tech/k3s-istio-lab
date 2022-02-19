#!/bin/sh

IP_ADDRESS=`ip addr | grep eth1 | grep inet | awk '{print $2}' | awk -F '/' '{print $1}'`

echo "[TASK 1] Install k3s"

cd /opt/k3s/
INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_EXEC="--disable traefik --node-ip ${IP_ADDRESS} --tls-san ${IP_ADDRESS} --flannel-iface eth1 --write-kubeconfig-mode 644" /opt/k3s/install.sh


echo "[TASK 2] Generate joincluster.sh"

K3S_URL=https://${IP_ADDRESS}:6443
K3S_TOKEN=`cat /var/lib/rancher/k3s/server/node-token`

sudo cat > /root/joincluster.sh <<EOF
#!/bin/bash
INSTALL_K3S_SKIP_DOWNLOAD=true K3S_URL=${K3S_URL} K3S_TOKEN=${K3S_TOKEN} INSTALL_K3S_EXEC="--node-ip 0.0.0.0 --flannel-iface eth1" /opt/k3s/install.sh
EOF
chmod +x /root/joincluster.sh
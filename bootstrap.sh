#!/bin/bash

K3S_VERSION="v1.23.3+k3s1"

echo "[TASK 1] Setting TimeZone"
timedatectl set-timezone Asia/Shanghai

echo "[TASK 2] Setting DNS"
cat >/etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8
FallbackDNS=223.5.5.5
EOF
systemctl daemon-reload
systemctl restart systemd-resolved.service
mv /etc/resolv.conf /etc/resolv.conf.bak
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

echo "[TASK 3] Setting Ubuntu System Mirrors"
cat >/etc/apt/sources.list<<EOF
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
apt update -qq >/dev/null 2>&1

echo "[TASK 4] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[TASK 5] Stop and Disable firewall"
systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 6] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 7] Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 8] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.56.101   k3s1
192.168.56.102   k3s2
192.168.56.103   k3s3
EOF

echo "[TASK 9] Download k3s and k3s images"

mkdir -p /opt/k3s/
cd /opt/k3s/
wget -q https://github.sfeng.workers.dev/https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s
wget -q https://github.sfeng.workers.dev/https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-airgap-images-amd64.tar.gz
wget -q https://github.sfeng.workers.dev/https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-images.txt
chmod +x k3s
mv k3s /usr/local/bin/
gunzip k3s-airgap-images-amd64.tar.gz
mkdir -p /var/lib/rancher/k3s/agent/images/
mv k3s-airgap-images-amd64.tar /var/lib/rancher/k3s/agent/images/
curl -sfL https://get.k3s.io -o /opt/k3s/install.sh
chmod +x /opt/k3s/install.sh

# echo "[TASK 10] Config k3s registry"

# sudo mkdir -p /etc/rancher/k3s
# sudo cat >> /etc/rancher/k3s/registries.yaml <<EOF
# mirrors:
#   "docker.io":
#     endpoint:
#       - "https://8bfcfsp1.mirror.aliyuncs.com"
#       - "https://bqr1dr1n.mirror.aliyuncs.com"
#       - "https://rw21enj1.mirror.aliyuncs.com"
#       - "https://vzv3mvs2.mirror.aliyuncs.com"
#       - "https://z82hcd5r.mirror.aliyuncs.com"
#       - "https://registry.cn-hangzhou.aliyuncs.com"
# EOF
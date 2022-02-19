#!/bin/sh

ISTIO_VERSION="1.12.3"
IP_ADDRESS=`ip addr | grep eth1 | grep inet | awk '{print $2}' | awk -F '/' '{print $1}'`

echo "下载 Istio"

cd /opt
# curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
wget -q https://github.sfeng.workers.dev/https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux-amd64.tar.gz
tar zxf istio-${ISTIO_VERSION}-linux-amd64.tar.gz
mv istio-${ISTIO_VERSION} istio
rm -fr istio-${ISTIO_VERSION}-linux-amd64.tar.gz
cd istio
export PATH=$PWD/bin:$PATH


echo "安装 Istio"
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
sed -i 's/127.0.0.1/'${IP_ADDRESS}'/' /root/.kube/config
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled

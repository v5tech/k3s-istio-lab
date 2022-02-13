# 一键安装k3s脚本，单节点模式
#!/bin/sh

K3S_VERSION="v1.23.3+k3s1"
KUBE_EXPLORER_VERSION="v0.2.8"

echo "[TASK 1] Download k3s and k3s images"

mkdir -p /opt/k3s/
cd /opt/k3s/
wget -q https://github.sfeng.workers.dev/https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s
wget -q https://github.sfeng.workers.dev/https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-airgap-images-amd64.tar.gz
wget -q https://github.sfeng.workers.dev/https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-images.txt

echo "[TASK 2] Config k3s registry"

sudo mkdir -p /etc/rancher/k3s
sudo cat >> /etc/rancher/k3s/registries.yaml <<EOF
mirrors:
  "docker.io":
    endpoint:
      - "https://8bfcfsp1.mirror.aliyuncs.com"
      - "https://bqr1dr1n.mirror.aliyuncs.com"
      - "https://rw21enj1.mirror.aliyuncs.com"
      - "https://vzv3mvs2.mirror.aliyuncs.com"
      - "https://z82hcd5r.mirror.aliyuncs.com"
      - "https://registry.cn-hangzhou.aliyuncs.com"
      - "https://docker.mirrors.ustc.edu.cn"
      - "https://dockerhub.azk8s.cn"
      - "https://quay.mirrors.ustc.edu.cn"
      - "https://quay.azk8s.cn"
      - "https://reg-mirror.qiniu.com"
      - "https://hub-mirror.c.163.com"
EOF

echo "[TASK 3] Install k3s"

chmod +x k3s
mv k3s /usr/local/bin/
gunzip k3s-airgap-images-amd64.tar.gz
mkdir -p /var/lib/rancher/k3s/agent/images/
mv k3s-airgap-images-amd64.tar /var/lib/rancher/k3s/agent/images/
curl -sfL https://get.k3s.io -o install.sh
chmod +x install.sh
INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_EXEC='--disable traefik' ./install.sh

echo "[TASK 4] Install kube-explorer"

wget -q https://github.sfeng.workers.dev/https://github.com/cnrancher/kube-explorer/releases/download/${KUBE_EXPLORER_VERSION}/kube-explorer-linux-amd64
mv kube-explorer-linux-amd64 kube-explorer
chmod +x kube-explorer
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
sed -i 's/127.0.0.1/192.168.56.100/' /root/.kube/config
nohup ./kube-explorer --kubeconfig=/root/.kube/config --http-listen-port=9898 --https-listen-port=0 >/dev/null 2>&1 &

echo "[TASK 5] Kubectl completion bash"

kubectl completion bash > /etc/bash_completion.d/kubectl
source /etc/bash_completion.d/kubectl
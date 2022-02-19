# k3s+istio

搭建k3s+istio环境

## 启动k3s集群

```bash
vagrant up
```

安装`kube-explorer dashboard`

```bash
cd /opt
wget -q https://github.sfeng.workers.dev/https://github.com/cnrancher/kube-explorer/releases/download/v0.2.8/kube-explorer-linux-amd64
mv kube-explorer-linux-amd64 kube-explorer
chmod +x kube-explorer
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
IP_ADDRESS=`ip addr | grep eth1 | grep inet | awk '{print $2}' | awk -F '/' '{print $1}'`
sed -i 's/127.0.0.1/'${IP_ADDRESS}'/' /root/.kube/config
nohup ./kube-explorer --kubeconfig=/root/.kube/config --http-listen-port=9898 --https-listen-port=0 >/dev/null 2>&1 &
```

浏览器访问 http://${IP_ADDRESS}:9898

设置`Kubectl Completion Bash`

```bash
kubectl completion bash > /etc/bash_completion.d/kubectl
source /etc/bash_completion.d/kubectl
```

## 安装istio

```bash
./install-istio.sh
```

设置`Istio Completion Bash`

```bash
istioctl completion bash > /etc/bash_completion.d/istioctl
source /etc/bash_completion.d/istioctl
```

istio部署bookinfo应用

```bash
# 部署示例应用
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl get services
kubectl get pods
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -s productpage:9080/productpage | grep -o "<title>.*</title>"

# 对外开放应用程序
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl get gateway
istioctl analyze

# 确定入站 IP 和端口
kubectl get svc istio-ingressgateway -n istio-system
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo "$GATEWAY_URL"

# 验证外部访问
echo "http://$GATEWAY_URL/productpage"

# 应用默认目标规则
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
kubectl get destinationrules -o yaml

# 查看仪表板
kubectl apply -f samples/addons
kubectl rollout status deployment/kiali -n istio-system
istioctl dashboard kiali --address=0.0.0.0
istioctl dashboard jaeger --address=0.0.0.0
istioctl dashboard grafana --address=0.0.0.0
```
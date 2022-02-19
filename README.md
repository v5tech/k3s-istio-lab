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

### istio部署bookinfo应用

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

# 清理bookinfo应用
samples/bookinfo/platform/kube/cleanup.sh
kubectl get virtualservices   #-- there should be no virtual services
kubectl get destinationrules  #-- there should be no destination rules
kubectl get gateway           #-- there should be no gateway
kubectl get pods              #-- the Bookinfo pods should be deleted
```

卸载istio

```bash
kubectl delete -f samples/addons
istioctl manifest generate --set profile=demo | kubectl delete --ignore-not-found=true -f -
kubectl delete namespace istio-system
kubectl label namespace default istio-injection-
```

### 部署google-samples-microservices

https://github.com/GoogleCloudPlatform/microservices-demo

* k3s集群部署应用

创建namespace

```bash
$ kubectl create ns google-samples-microservices
```

应用配置，部署应用

```bash
$ kubectl apply -n google-samples-microservices -f kubernetes-manifests.yaml

$ kubectl get pod -n google-samples-microservices
NAME                                     READY   STATUS    RESTARTS   AGE
svclb-frontend-external-2sg5q            0/1     Pending   0          2m57s
svclb-frontend-external-9rfq4            0/1     Pending   0          2m57s
checkoutservice-558b447fdc-9dnmx         1/1     Running   0          2m58s
shippingservice-7b64ffc765-kvzfv         1/1     Running   0          2m55s
redis-cart-78746d49dc-wbrhm              1/1     Running   0          2m55s
productcatalogservice-cc7c79cf5-b4wlp    1/1     Running   0          2m56s
frontend-8446f74795-8nghz                1/1     Running   0          2m57s
cartservice-d7f69f549-jckfq              1/1     Running   0          2m56s
currencyservice-7d5c4974b9-p5sz7         1/1     Running   0          2m56s
paymentservice-6fd9ff5d6c-tg4cx          1/1     Running   0          2m57s
loadgenerator-d95bc946f-j562g            1/1     Running   0          2m56s
emailservice-f57d5c6c9-lm6xv             1/1     Running   0          2m58s
recommendationservice-79fd4d769c-dd6bc   1/1     Running   0          2m58s
adservice-65d4dc6b67-pmth7               1/1     Running   0          2m55s

$ kubectl get svc -n google-samples-microservices
NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
emailservice            ClusterIP      10.43.182.252   <none>        5000/TCP       3m
checkoutservice         ClusterIP      10.43.122.110   <none>        5050/TCP       3m
recommendationservice   ClusterIP      10.43.150.235   <none>        8080/TCP       3m
frontend                ClusterIP      10.43.198.168   <none>        80/TCP         2m59s
frontend-external       LoadBalancer   10.43.237.62    <pending>     80:30841/TCP   2m59s
paymentservice          ClusterIP      10.43.200.157   <none>        50051/TCP      2m59s
productcatalogservice   ClusterIP      10.43.194.205   <none>        3550/TCP       2m58s
cartservice             ClusterIP      10.43.218.17    <none>        7070/TCP       2m58s
currencyservice         ClusterIP      10.43.223.195   <none>        7000/TCP       2m57s
shippingservice         ClusterIP      10.43.129.253   <none>        50051/TCP      2m57s
redis-cart              ClusterIP      10.43.156.117   <none>        6379/TCP       2m57s
adservice               ClusterIP      10.43.155.192   <none>        9555/TCP       2m57s
```

浏览器访问 http://192.168.56.101:30841

* 为微服务启用istio

```bash
kubectl create ns istio-app
kubectl label ns istio-app istio-injection=enabled
kubectl apply -n istio-app -f kubernetes-manifests.yaml
kubectl get pod -n istio-app
kubectl delete svc frontend-external -n istio-app
kubectl get svc -n istio-system
kubectl apply -n istio-app -f istio-manifests.yaml
kubectl delete serviceentry allow-egress-google-metadata -n istio-app
kubectl delete serviceentry allow-egress-googleapis -n istio-app
```

浏览器访问 http://192.168.56.101:30792 (端口`30792`为`kubectl get svc -n istio-system`的80端口暴露出来的端口)

* istio金丝雀发布

```bash
kubectl delete deploy productcatalogservice -n istio-app
```

productcatalog-v1.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productcatalogservice-v1
spec:
  selector:
    matchLabels:
      app: productcatalogservice
  template:
    metadata:
      labels:
        app: productcatalogservice
        # 指定为 v1 版本
        version: v1
    spec:
      serviceAccountName: default
      terminationGracePeriodSeconds: 5
      containers:
      - name: server
        image: docker.io/v5cn/google-samples-microservices-productcatalogservice:v0.3.6
        ports:
        - containerPort: 3550
        env:
        - name: PORT
          value: "3550"
        - name: DISABLE_STATS
          value: "1"
        - name: DISABLE_TRACING
          value: "1"
        - name: DISABLE_PROFILER
          value: "1"
        readinessProbe:
          exec:
            command: ["/bin/grpc_health_probe", "-addr=:3550"]
        livenessProbe:
          exec:
            command: ["/bin/grpc_health_probe", "-addr=:3550"]
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
```

```bash
kubectl apply -n istio-app -f productcatalog-v1.yaml
kubectl get deploy productcatalogservice-v1 -n istio-app
```

productcatalog-v2.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productcatalogservice-v2
spec:
  selector:
    matchLabels:
      app: productcatalogservice
  template:
    metadata:
      labels:
        app: productcatalogservice
        # 指定为 v2 版本
        version: v2
    spec:
      containers:
      - env:
        - name: PORT
          value: '3550'
        - name: EXTRA_LATENCY
          value: 3s
        image: docker.io/v5cn/google-samples-microservices-productcatalogservice:v0.3.6
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:3550
        name: server
        ports:
        - containerPort: 3550
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:3550
        resources:
          limits:
            cpu: 200m
            memory: 128Mi
          requests:
            cpu: 100m
            memory: 64Mi
      terminationGracePeriodSeconds: 5
```

```bash
kubectl apply -n istio-app -f productcatalog-v2.yaml
kubectl get deploy productcatalogservice-v2 -n istio-app
```

vs-split-traffic.yaml

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productcatalogservice
spec:
  hosts:
  - productcatalogservice
  http:
  - route:
    - destination:
        host: productcatalogservice
        subset: v1
      weight: 75
    - destination:
        host: productcatalogservice
        subset: v2
      weight: 25
```

```bash
kubectl apply -n istio-app -f vs-split-traffic.yaml
```

destinationrule.yaml

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productcatalogservice
spec:
  host: productcatalogservice
  subsets:
    - labels:
        app: productcatalogservice
        version: v1
      name: v1
    - labels:
        app: productcatalogservice
        version: v2
      name: v2
```

```bash
kubectl apply -n istio-app -f destinationrule.yaml
```
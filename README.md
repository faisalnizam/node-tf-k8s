# Node Run on Minikube
Following Example lets you provision the following resources using Terraform 

* VPC For Provisioning of Resournces
* Subnets and Default Security Group
* SSH Key to be attached to instance
* EC2 Instance to Run K8S Instance 


* Docker MongoDB if running locally 
If you want to run the entire project outside with a dockerized mongo use
```
docker run -d  --name mongo-docker  -p 27017:27017 mongo
```

# Compile Docker Image 
```
cd app 
docker build . -t nodeapp/myimage 

```

# To Run Project Locally using docker-compose 

```
cd app/
docker-compose up -d 
curl localhost:3000

```


# Jenkinsfile
* In order to run the project using Jenkins and see the pipeline you can use the following as a reference 

```
cd Jenkins
cat Jenkinsfile 
```

# Install Kind Cluster Or Minikube 

Once the  Cluster is ready cd into ingress and run deploy (Note: this is only for local deployments) 
If you want to use minikube, here is a quick howto link to help you start the cluster https://phoenixnap.com/kb/install-minikube-on-ubuntu


# Create a Cluster ( I am using kind but you can use minikube and enable ingresss using kdata or the manifest from the project) 
```
cat <<EOF | kind create cluster --config=-
> kind: Cluster
> apiVersion: kind.x-k8s.io/v1alpha4
> nodes:
> - role: control-plane
>   kubeadmConfigPatches:
>   - |
>     kind: InitConfiguration
>     nodeRegistration:
>       kubeletExtraArgs:
>         node-labels: "ingress-ready=true"
>   extraPortMappings:
>   - containerPort: 80
>     hostPort: 80
>     protocol: TCP
>   - containerPort: 443
>     hostPort: 443
>     protocol: TCP
> EOF
```
# Optional : Configure GUI For General Adminsitartion 
* Install GUI for K8S 
* Once you have K8S (Kind/Minikube) successfully installed and your context is set to your cluster install the GUI 

```
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm install dashboard kubernetes-dashboard/kubernetes-dashboard -n kubernetes-dashboard --create-namespace
export POD_NAME=$(kubectl get pods -n kubernetes-dashboard -l "app.kubernetes.io/name=kubernetes-dashboard,app.kubernetes.io/instance=dashboard" -o jsonpath="{.items[0].metadata.name}")
echo https://127.0.0.1:8443/

# Run in BackGround 
kubectl -n kubernetes-dashboard port-forward $POD_NAME 8443:8443i & 
```

# Open URL 
```
curl https://localhost:8443/
```


# Manifests 

All manifests are located within the manifest directory 

manifest/jenkins  `To Install Jenkins on your cluster and create ingress rules to expose it outisde`
manifest/ingress  `To Install NGINX Ingress Controller`
manifest/mongo    `To Install mongodb on the cluster and expose via nodeport` 
manifest/app      `To Deploy app and configure the Ingress` 


* Configure Ingress (NGINX) using the service

Change  Directory to manifest/

```
kubectl apply -f ingress/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```


# Ports Allocation 

* Jenkins : 32000
* App     : 32001
* Mongodb : 32002 


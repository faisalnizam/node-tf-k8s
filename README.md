# Node Run on Minikube
Following Example lets you provision the following resources using Terraform 

* VPC For Provisioning of Resournces
* Subnets and Default Security Group
* SSH Key to be attached to instance
* EC2 Instance to Run K8S Instance 

# Pre-Req to Run 

* Python3 
* pip3 install path
* pip3 install python-terraform



# Install Kind Cluster Or Minikube 

Once the  Cluster is ready cd into ingress and run deploy (Note: this is only for local deployments) 

kubectl apply -f ingress/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

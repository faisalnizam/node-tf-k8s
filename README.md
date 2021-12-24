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

# Install GUI for K8S 
Once you have K8S (Kind/Minikube) successfully installed and your context is set to your cluster install the GUI 

* helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
* helm install dashboard kubernetes-dashboard/kubernetes-dashboard -n kubernetes-dashboard --create-namespace


'''export POD_NAME=$(kubectl get pods -n kubernetes-dashboard -l "app.kubernetes.io/name=kubernetes-dashboard,app.kubernetes.io/instance=dashboard" -o jsonpath="{.items[0].metadata.name}")

'''echo https://127.0.0.1:8443/

# Run in BackGround 
'''kubectl -n kubernetes-dashboard port-forward $POD_NAME 8443:8443i & 


# Open URL 
'''https://localhost:8443/


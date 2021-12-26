#! /bin/bash 

echo "Deploy Service on Your Cluster" 
echo "Create Namespace to deploy our services" 

kubectl create namespace nodeapp

kubectl create namespace jenkins

# Install jenkins 
helm repo add jenkinsci https://charts.jenkins.io
helm repo update

chart=jenkinsci/jenkins
helm install jenkins -n jenkins -f jenkins/jk-override-values.yaml $chart


# Install Cert Manager 

helm repo add jetstack https://charts.jetstack.io
helm repo update


helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.5.3 --set installCRDs=true
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.crds.yaml


curl -L -o kubectl-cert-manager.tar.gz https://github.com/jetstack/cert-manager/releases/latest/download/kubectl-cert_manager-linux-amd64.tar.gz
tar xzf kubectl-cert-manager.tar.gz
sudo mv kubectl-cert_manager /usr//bin



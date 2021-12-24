#! /bin/bash 

echo "hello world" 

sudo apt-get update -y
sudo apt-get -y install curl
sudo apt-get -y install apt-transport-https
sudo apt-get -y install aws-cli


# Download the binary 

wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo cp minikube-linux-amd64 /usr/local/bin/minikube
sudo chmod 755 /usr/local/bin/minikube

minikube version > /tmp/minikube-verion.tmp

# Download Kubectl 
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
sudo chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Check version 
kubectl version -o json > /tmp/kubectl-version.tmp


# Start MiniKube
sudo minikube start 


#Copy Confg to Tmp to be moved to s3
sudo kubectl config view > confg-view.tmp
sudo kubectl cluster-info > cluster-info.tmp 

# Use SSH Port Forwarding to connect to cluster 
# ssh -N -p 22 <user>@<public_ip> -L 127.0.0.1:18443:<minikube_ip>:8443


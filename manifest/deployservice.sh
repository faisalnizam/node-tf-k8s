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



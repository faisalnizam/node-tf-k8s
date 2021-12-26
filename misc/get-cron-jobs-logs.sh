# /bin/bash 

echo "Enter Namespace" 
read namespace 


jobs=( $(kubectl get jobs --no-headers -o custom-columns=":metadata.name" -n $namespace) )
for job in "${jobs[@]}"
do
   pod=$(kubectl get pods -l job-name=$job --no-headers -o custom-columns=":metadata.name" -n $namespace)
   kubectl logs $pod
done

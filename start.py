import os
import sys
import subprocess
from path import Path


print("================")
print("Setup Environment Automation\n") 


profile = input("Enter AWS Profile to use : ")

region = input("Enter Region to User: ")

vpcname = input("Enter VPC Name to Create: "); 

cidr = input("Enter CIDR for VPC to Use e.g 10.20.0.0/18:  ")

os.chdir('terraform/env')

terraformCommand = "terraform plan -var region=eu-west-1 -var vpcname=swycl-vpc -var cidr=10.10.0.0/16 -var profile=lyve_qa "
process = subprocess.Popen(terraformCommand, shell=True,  stdout=subprocess.PIPE)
print(process.communicate()).decode('utf-8')


#out, err = process.communicate()
#print(out)
#process.stdout.decode('utf-8')
#print(process.communicate())

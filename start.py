import sys
import subprocess
import os

home_dir = os.system("cd ~")
print("================")
print("Setup Environment Automation\n") 


profile = input("Enter AWS Profile to use : ")

region = input("Enter Region to User: ")

vpcname = input("Enter VPC Name to Create: "); 

cidr = input("Enter CIDR for VPC to Use e.g 10.20.0.0/18:  ")


#bashCommand = "ls -lash"
#process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
#print(process.communicate())


#!/bin/bash

#create choice for shell with options 

usage() { echo "Usage:
./deploy.sh -s <create>/<delete> -k <Key ID> -i <Instance ID>" }

while getopts ":s" o; do
    case "${o}" in
        s)  action=${OPTARG};;
        k)  keyID =${OPTARG};;
        i)  instanceID = ${OPTARG};;
*) usage();;
    esac
done

if [[ action -eq 'create' ]]
then

#create EC2 Code steps 

# Authorize TCP, SSH & ICMP for default Security Group
ec2-authorize default -P icmp -t -1:-1 -s 0.0.0.0/0
ec2-authorize default -P tcp -p 22 -s 0.0.0.0/0
ec2-authorize default -P tcp -p 80 -s 0.0.0.0/0
ec2-authorize default -P tcp -p 443 -s 0.0.0.0/0

# The Static IP Address for this instance:
IP_ADDRESS=`cat ~/.ec2/ip_address`

EC2_RUN_RESULT=`ec2-run-instances --instance-type t1.micro --group default --key $keyID --block-device-mapping "/dev/sda1=:16:true" --instance-initiated-shutdown-behavior delete --user-data-file instance_installs.sh ami-74f0061d`

INSTANCE_NAME=`echo ${EC2_RUN_RESULT} | sed 's/RESERVATION.*INSTANCE //' | sed 's/ .*//'`

ec2-associate-address $IP_ADDRESS -i $INSTANCE_NAME

echo
echo Instance $INSTANCE_NAME has been created and assigned static IP Address $IP_ADDRESS
echo

ssh-keygen -R $IP_ADDRESS
ssh -i $EC2_HOME/$EC2_INSTANCE_KEY.pem ec2-user@$IP_ADDRESS

# installaing web server and trying to get ec2 cli 

yum install httpd -y
/sbin/chkconfig --levels 235 httpd on
service httpd create
instanceId=$(curl http://$IP_ADDRESS/latest/meta-data/instance-id)
region=$(curl http://$IP_ADDRESS/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
echo "<h1>$instanceId</h1>" > /var/www/html/index.html



else if [[ action -eq 'delete' ]]
then
#delete EC2 Code steps 

aws ec2 terminate-instances --instance-ids $instanceID
#!/bin/bash
usage() { echo "Usage:
./deploy.sh -s <create>/<delete>" }

while getopts ":s" o; do
    case "${o}" in
        s)  action=${OPTARG};;
*) usage();;
    esac
done

if [[ action -eq 'create' ]]
then

#create EC2 Code

# Authorize TCP, SSH & ICMP for default Security Group
ec2-authorize default -P icmp -t -1:-1 -s 0.0.0.0/0
ec2-authorize default -P tcp -p 22 -s 0.0.0.0/0
ec2-authorize default -P tcp -p 80 -s 0.0.0.0/0
ec2-authorize default -P tcp -p 443 -s 0.0.0.0/0

# The Static IP Address for this instance:
IP_ADDRESS=`cat ~/.ec2/ip_address`

# Create new t1.micro instance using ami-74f0061d (Basic 64-bit Amazon Linux AMI 2010.11.1 Beta)
# using the default security group and a 16GB EBS datastore as /dev/sda1.
# EC2_INSTANCE_KEY is an environment variable containing the name of the instance key.
# --block-device-mapping ...:false to leave the disk image around after terminating instance
EC2_RUN_RESULT=`ec2-run-instances --instance-type t1.micro --group default --key $EC2_INSTANCE_KEY --block-device-mapping "/dev/sda1=:16:true" --instance-initiated-shutdown-behavior delete --user-data-file instance_installs.sh ami-74f0061d`

INSTANCE_NAME=`echo ${EC2_RUN_RESULT} | sed 's/RESERVATION.*INSTANCE //' | sed 's/ .*//'`

ec2-associate-address $IP_ADDRESS -i $INSTANCE_NAME

echo
echo Instance $INSTANCE_NAME has been created and assigned static IP Address $IP_ADDRESS
echo

# Since the server signature changes each time, remove the server's entry from ~/.ssh/known_hosts
# Maybe you don't need to do this if you're using a Reserved Instance?
ssh-keygen -R $IP_ADDRESS

# SSH into my BRAND NEW EC2 INSTANCE! WooHoo!!!
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
#delete EC2 Code

aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
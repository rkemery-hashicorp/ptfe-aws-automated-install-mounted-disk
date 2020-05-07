#! /bin/bash
rm -f ~/.ssh/known_hosts
terraform show | sed -n '/BEGIN RSA PRIVATE KEY/','/END RSA PRIVATE KEY'/p > /tmp/ssh.key
sed -r 's/^[[:blank:]]+//' /tmp/ssh.key > /tmp/aws.key
rm -f /tmp/ssh.key
chmod 600 /tmp/aws.key
aws_ip=$(terraform show | grep public_ip | awk '/^public_ip/{print $NF}' | sed -e 's/^"//' -e 's/"$//')
ssh -o StrictHostKeyChecking=no -i /tmp/aws.key ubuntu@$aws_ip 

#!/bin/bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
echo 'ec2-user1234!' | passwd --stdin ec2-user
yum update -y
yum install -y lynx python3-pip
pip install flask boto3
aws configure set region ap-northeast-2
aws s3 cp s3://${bucket_name} /home/ec2-user --recursive
nohup python3 -u /home/ec2-user/app.py > /home/ec2-user/nohup.out 2>&1 &
#!/bin/bash
yum update -y
yum install -y ruby docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
AWS_DEFAULT_REGION="ap-northeast-2"
wget https://aws-codedeploy-$AWS_DEFAULT_REGION.s3.$AWS_DEFAULT_REGION.amazonaws.com/latest/install
chmod +x ./install
./install auto
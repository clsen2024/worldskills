#!/bin/bash
python3 -m ensurepip --default-pip
aws s3 cp s3://${bucket_name} /home/ec2-user --recursive
pip install -r /home/ec2-user/requirements.txt
nohup python3 -u /home/ec2-user/main.py > /home/ec2-user/nohup.out 2>&1 &
#!/bin/bash
python3 -m ensurepip --default-pip
pip install flask
mkdir -p /opt/app
cd /opt/app
aws s3 cp s3://${bucket_name}/app.py .
nohup python3 -u app.py > nohup.out 2>&1 &
curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh
cd /etc/fluent-bit
aws s3 cp s3://${bucket_name}/fluent-bit.conf .
aws s3 cp s3://${bucket_name}/parsers.conf .
sed -i "s/opensearch_url/${opensearch_url}/g" fluent-bit.conf
systemctl start fluent-bit
systemctl enable fluent-bit
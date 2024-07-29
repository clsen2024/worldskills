#!/bin/bash
REPOSITORY=$(cat /home/ec2-user/repository.txt)
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin "$(echo "$REPOSITORY" | cut -d '/' -f 1)"
docker pull "$REPOSITORY"
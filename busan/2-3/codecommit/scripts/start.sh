#!/bin/bash
REPOSITORY=$(cat /home/ec2-user/repository.txt)
docker run -d -p 80:8080 --name wsi-app "$REPOSITORY"
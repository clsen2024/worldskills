#!/bin/bash
docker stop wsi-app && echo "Stop Server" || echo "Not Running"
docker rm wsi-app && echo "Remove Server" || echo "Not Running"
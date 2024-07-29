import time
import boto3

logs = boto3.client('logs')

def lambda_handler(event, context):
    logs.put_log_events(
        logGroupName='wsi-project-login',
        logStreamName=f'wsi-project-login-stream',
        logEvents=[
            {
                'timestamp': round(time.time()*1000),
                'message': '{ USER: "wsi-project-user has logged in!" }'
            },
        ],
        sequenceToken='string'
    )
import boto3
import json
import os
import secrets
import string

def generate_random_password(length=16):
    alphabet = string.ascii_letters + string.digits + string.punctuation
    password = ''.join(secrets.choice(alphabet) for _ in range(length))
    return password

def lambda_handler(event, context):
    secretsmanager_client = boto3.client('secretsmanager')
    rds_client = boto3.client('rds')

    secret_arn = os.environ["SECRET_ARN"]
    cluster_identifier = os.environ["CLUSTER_IDENTIFIER"]
    response = secretsmanager_client.get_secret_value(
        SecretId=secret_arn
    )
    secret_value = json.loads(response['SecretString'])

    new_password = generate_random_password()
    rds_client.modify_db_cluster(
        DBClusterIdentifier=cluster_identifier,
        MasterUserPassword=new_password,
        ApplyImmediately=True
    )

    secretsmanager_client.put_secret_value(
        SecretId=secret_arn,
        SecretString=json.dumps({
            "MYSQL_USER": secret_value["MYSQL_USER"],
            "MYSQL_PASSWORD": new_password,
            "MYSQL_HOST": secret_value["MYSQL_HOST"],
            "MYSQL_PORT": secret_value["MYSQL_PORT"],
            "MYSQL_DBNAME": secret_value["MYSQL_DBNAME"]
        })
    )

    return {
        'statusCode': 200,
        'body': json.dumps('Secret rotated successfully')
    }
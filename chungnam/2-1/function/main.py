import boto3

iam = boto3.client('iam')

def lambda_handler(event, context):
    roleName = "wsc2024-instance-role"
    response = iam.list_attached_role_policies(
        RoleName=roleName
    )
    for policy in response["AttachedPolicies"]:
        if policy["PolicyName"] != "AmazonSSMManagedInstanceCore":
            iam.detach_role_policy(
                RoleName=roleName,
                PolicyArn=policy["PolicyArn"]
            )
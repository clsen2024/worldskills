import boto3
import botocore
import json

APPLICABLE_RESOURCES = ["AWS::EC2::SecurityGroup"]

def evaluate_compliance(configuration_item):
    if configuration_item["resourceType"] not in APPLICABLE_RESOURCES:
        return {
            "compliance_type" : "NOT_APPLICABLE",
            "annotation" : "The rule doesn't apply to resources of type " +
            configuration_item["resourceType"] + "."
        }

    if configuration_item["configurationItemStatus"] == "ResourceDeleted":
        return {
            "compliance_type": "NOT_APPLICABLE",
            "annotation": "The configurationItem was deleted and therefore cannot be validated."
        }

    group_id = configuration_item["configuration"]["groupId"]
    ec2 = boto3.client("ec2")

    response = ec2.describe_instances(
        Filters=[
            {
                'Name': 'tag:Name',
                'Values': [
                    'wsi-test',
                ]
            }
        ]
    )

    securityGroups = [securityGroup['GroupId'] for securityGroup in response['Reservations'][0]['Instances'][0]['SecurityGroups']]
    if group_id not in securityGroups:
        return {
            "compliance_type": "COMPLIANT",
            "annotation": "The group is in the exception list."
        }

    try:
        response = ec2.describe_security_groups(GroupIds=[group_id])
    except botocore.exceptions.ClientError as e:
        return {
            "compliance_type" : "NON_COMPLIANT",
            "annotation" : "describe_security_groups failure on group " + group_id
        }

    sg_ingress = response["SecurityGroups"][0]["IpPermissions"]
    REQUIRED_INGRESS = [
        {"IpProtocol" : "tcp","FromPort" : 22,"ToPort" : 22,"UserIdGroupPairs" : [],"IpRanges" : [{"CidrIp" : "118.221.173.107/32"}],"PrefixListIds" : [],"Ipv6Ranges" : []},
        {"IpProtocol" : "tcp","FromPort" : 80,"ToPort" : 80,"UserIdGroupPairs" : [{"GroupId": group_id, "UserId": "828680151668"}],"IpRanges" : [],"Ipv6Ranges" : [],"PrefixListIds" : []},
        {"IpProtocol" : "tcp","FromPort" : 3306,"ToPort" : 3306,"UserIdGroupPairs" : [{"GroupId": group_id, "UserId": "828680151668"}],"IpRanges" : [],"Ipv6Ranges" : [],"PrefixListIds" : []}
    ]
    REQUIRED_EGRESS = [
        {"IpProtocol" : "tcp","FromPort" : 22,"ToPort" : 22,"UserIdGroupPairs" : [],"IpRanges" : [{"CidrIp" : "0.0.0.0/0"}],"PrefixListIds" : [],"Ipv6Ranges" : []},
        {"IpProtocol" : "tcp","FromPort" : 80,"ToPort" : 80,"UserIdGroupPairs" : [],"IpRanges" : [{"CidrIp" : "0.0.0.0/0"}],"PrefixListIds" : [],"Ipv6Ranges" : []}, 
        {"IpProtocol" : "tcp","FromPort" : 443,"ToPort" : 443,"UserIdGroupPairs" : [],"IpRanges" : [{"CidrIp" : "0.0.0.0/0"}],"PrefixListIds" : [],"Ipv6Ranges" : []}
    ]
    authorize_ingress = [item for item in REQUIRED_INGRESS if item not in sg_ingress]
    revoke_ingress = [item for item in sg_ingress if item not in REQUIRED_INGRESS]

    if authorize_ingress or revoke_ingress:
        annotation_message = "Permissions were modified."
    else:
        annotation_message = "Permissions are correct."

    if authorize_ingress:
        try:
            ec2.authorize_security_group_ingress(GroupId=group_id, IpPermissions=authorize_ingress)
            annotation_message += " ingress : " + str(len(authorize_ingress)) + " new authorization(s)."
        except botocore.exceptions.ClientError as e:
            return {
                "compliance_type" : "NON_COMPLIANT",
                "annotation" : "authorize_security_group_ingress failure on group " + group_id
            }

    if revoke_ingress:
        try:
            ec2.revoke_security_group_ingress(GroupId=group_id, IpPermissions=revoke_ingress)
            annotation_message += " ingress : " + str(len(revoke_ingress)) + " new revocation(s)."
        except botocore.exceptions.ClientError as e:
            return {
                "compliance_type" : "NON_COMPLIANT",
                "annotation" : "revoke_security_group_ingress failure on group " + group_id
            }

    sg_egress = response["SecurityGroups"][0]["IpPermissionsEgress"]
    authorize_egress = [item for item in REQUIRED_EGRESS if item not in sg_egress]
    revoke_egress = [item for item in sg_egress if item not in REQUIRED_EGRESS]

    if authorize_egress or revoke_egress:
        annotation_message = "Permissions were modified."
    else:
        annotation_message = "Permissions are correct."

    if authorize_egress:
        try:
            ec2.authorize_security_group_egress(GroupId=group_id, IpPermissions=authorize_egress)
            annotation_message += " egress : " + str(len(authorize_egress)) + " new authorization(s)."
        except botocore.exceptions.ClientError as e:
            return {
                "compliance_type" : "NON_COMPLIANT",
                "annotation" : "authorize_security_group_egress failure on group " + group_id
            }

    if revoke_egress:
        try:
            ec2.revoke_security_group_egress(GroupId=group_id, IpPermissions=revoke_egress)
            annotation_message += " egress : " + str(len(revoke_egress)) + " new revocation(s)."
        except botocore.exceptions.ClientError as e:
            return {
                "compliance_type" : "NON_COMPLIANT",
                "annotation" : "revoke_security_group_egress failure on group " + group_id
            }

    return {
        "compliance_type": "COMPLIANT",
        "annotation": annotation_message
    }

def lambda_handler(event, context):
    print(event)
    invoking_event = json.loads(event['invokingEvent'])
    configuration_item = invoking_event["configurationItem"]

    evaluation = evaluate_compliance(configuration_item)

    config = boto3.client('config')

    config.put_evaluations(
        Evaluations=[
            {
                'ComplianceResourceType': invoking_event['configurationItem']['resourceType'],
                'ComplianceResourceId': invoking_event['configurationItem']['resourceId'],
                'ComplianceType': evaluation["compliance_type"],
                "Annotation": evaluation["annotation"],
                'OrderingTimestamp': invoking_event['configurationItem']['configurationItemCaptureTime']
            },
        ],
        ResultToken=event['resultToken'])
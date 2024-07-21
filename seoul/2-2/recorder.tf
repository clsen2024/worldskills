resource "aws_config_configuration_recorder" "main" {
  name     = "default"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = false
    include_global_resource_types = false
    resource_types                = ["AWS::EC2::SecurityGroup"]
  }

  recording_mode {
    recording_frequency = "CONTINUOUS"
  }
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_config_delivery_channel" "main" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config.bucket
}

resource "aws_s3_bucket" "config" {
  bucket_prefix = "worldskills-awsconfig-"
  force_destroy = true
}

resource "aws_iam_role" "config" {
  name               = "AWSConfigRole"
  assume_role_policy = data.aws_iam_policy_document.config.json
}

data "aws_iam_policy_document" "config" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/aws-service-role/AWSConfigServiceRolePolicy"
}

resource "aws_config_config_rule" "preserve" {
  name = "wsi-rule"

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.preserve.arn
  }

  depends_on = [
    aws_config_configuration_recorder.main,
    aws_lambda_permission.preserve,
  ]
}
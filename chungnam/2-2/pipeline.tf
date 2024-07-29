resource "aws_codecommit_repository" "main" {
  repository_name = "wsc2024-cci"
  default_branch = "main"
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "codebuild-wsc2024-cbd-service-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    effect = "Allow"

    resources = [
      "arn:aws:logs:us-west-1:${local.account_id}:log-group:/codebuild/wsc2024-cbd",
      "arn:aws:logs:us-west-1:${local.account_id}:log-group:/codebuild/wsc2024-cbd:*",
    ]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:s3:::codepipeline-us-west-1-*", "arn:aws:s3:::dockerfile-temp-${local.account_id}/*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
  }

  statement {
    effect    = "Allow"
    resources = [aws_codecommit_repository.main.arn]
    actions   = ["codecommit:GitPull"]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

resource "aws_iam_role_policy_attachment" "ecr_push" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_codebuild_project" "main" {
  name          = "wsc2024-cbd"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }
    environment_variable {
      name  = "REPOSITORY_NAME"
      value = aws_ecr_repository.main.name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/wsc2024-cbd"
      stream_name = "ecr-"
    }
  }

  source {
    type     = "CODECOMMIT"
    location = aws_codecommit_repository.main.clone_url_http
  }
}

resource "aws_codedeploy_app" "main" {
  compute_platform = "ECS"
  name             = "wsc2024-cdy"
}

resource "aws_codedeploy_deployment_group" "main" {
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = "wsc2024-cdy-dg"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy.arn

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.main.name
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_alb_listener.alb_http.arn]
      }
      target_group {
        name = aws_alb_target_group.blue.name
      }
      target_group {
        name = aws_alb_target_group.green.name
      }
    }
  }
}

data "aws_iam_policy_document" "codedeploy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "AWSCodeDeployRoleForECS"
  assume_role_policy = data.aws_iam_policy_document.codedeploy.json
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.codedeploy.name
}

resource "aws_codepipeline" "main" {
  name           = "wsc2024-pipeline"
  role_arn       = aws_iam_role.codepipeline.arn
  pipeline_type  = "V2"
  execution_mode = "QUEUED"

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      namespace        = "CodecommitVariable"

      configuration = {
        RepositoryName       = aws_codecommit_repository.main.repository_name
        BranchName           = "main"
        PollForSourceChanges = false
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  stage {
    name = "CodeCommit_Check"

    action {
      name     = "ApproveChangeSet"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData         = "new CommitID : #{CodecommitVariable.CommitId}"
        ExternalEntityLink = "https://us-west-1.console.aws.amazon.com/codesuite/codecommit/repositories/${aws_codecommit_repository.main.repository_name}/commit/#{CodecommitVariable.CommitId}?region=us-west-1"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["BuildArtifact"]

      configuration = {
        ApplicationName                = aws_codedeploy_app.main.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.main.deployment_group_name
        AppSpecTemplateArtifact        = "BuildArtifact"
        AppSpecTemplatePath            = "appspec.yml"
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        TaskDefinitionTemplatePath     = "taskdef.json"
        Image1ArtifactName             = "BuildArtifact"
        Image1ContainerName            = "IMAGE"
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline" {
  bucket        = "codepipeline-us-west-1-${local.account_id}"
  force_destroy = true
}

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "AWSCodePipelineServiceRole-us-west-1-wsc2024-pipeline"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["iam:PassRole"]

    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"

      values = [
        "cloudformation.amazonaws.com",
        "elasticbeanstalk.amazonaws.com",
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com",
      ]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "codecommit:CancelUploadArchive",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetRepository",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:UploadArchive",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["codestar-connections:UseConnection"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticbeanstalk:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "cloudformation:*",
      "rds:*",
      "sqs:*",
      "ecs:*",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "lambda:InvokeFunction",
      "lambda:ListFunctions",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "opsworks:CreateDeployment",
      "opsworks:DescribeApps",
      "opsworks:DescribeCommands",
      "opsworks:DescribeDeployments",
      "opsworks:DescribeInstances",
      "opsworks:DescribeStacks",
      "opsworks:UpdateApp",
      "opsworks:UpdateStack",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "cloudformation:CreateStack",
      "cloudformation:DeleteStack",
      "cloudformation:DescribeStacks",
      "cloudformation:UpdateStack",
      "cloudformation:CreateChangeSet",
      "cloudformation:DeleteChangeSet",
      "cloudformation:DescribeChangeSet",
      "cloudformation:ExecuteChangeSet",
      "cloudformation:SetStackPolicy",
      "cloudformation:ValidateTemplate",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuildBatches",
      "codebuild:StartBuildBatch",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "devicefarm:ListProjects",
      "devicefarm:ListDevicePools",
      "devicefarm:GetRun",
      "devicefarm:GetUpload",
      "devicefarm:CreateUpload",
      "devicefarm:ScheduleRun",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "servicecatalog:ListProvisioningArtifacts",
      "servicecatalog:CreateProvisioningArtifact",
      "servicecatalog:DescribeProvisioningArtifact",
      "servicecatalog:DeleteProvisioningArtifact",
      "servicecatalog:UpdateProduct",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["cloudformation:ValidateTemplate"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ecr:DescribeImages"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "states:DescribeExecution",
      "states:DescribeStateMachine",
      "states:StartExecution",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "appconfig:StartDeployment",
      "appconfig:StopDeployment",
      "appconfig:GetDeployment",
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "CodepipelinePolicy"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}
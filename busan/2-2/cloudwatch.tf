resource "aws_cloudwatch_log_group" "cloudtrail" {
  name = "wsi-project-trail-logs"
}

resource "aws_cloudwatch_log_subscription_filter" "main" {
  name            = "project_user_login"
  log_group_name  = aws_cloudwatch_log_group.cloudtrail.name
  filter_pattern  = "{ $.eventName = \"ConsoleLogin\" && $.userIdentity.userName = \"wsi-project-user\" }"
  destination_arn = aws_lambda_function.main.arn
  distribution    = "Random"
}

resource "aws_cloudwatch_log_group" "main" {
  name = "wsi-project-login"
}

resource "aws_cloudwatch_log_stream" "main" {
  name           = "wsi-project-login-stream"
  log_group_name = aws_cloudwatch_log_group.main.name
}
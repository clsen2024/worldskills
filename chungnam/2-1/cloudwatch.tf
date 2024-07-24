resource "aws_cloudwatch_log_group" "main" {
  name = "wsc2024-gvn-LG"
}

resource "aws_cloudwatch_log_metric_filter" "main" {
  name           = "illegal_rule_add"
  pattern        = "{($.eventName = \"AttachRolePolicy\") && ($.requestParameters.roleName = \"wsc2024-instance-role\") && ($.userIdentity.userName = \"Employee\")}"
  log_group_name = aws_cloudwatch_log_group.main.name

  metric_transformation {
    name      = "illegalRuleAdd"
    namespace = "wsc2024"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "main" {
  alarm_name          = "wsc2024-gvn-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.main.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.main.metric_transformation[0].namespace
  period              = 10
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [aws_lambda_function.main.arn]
}
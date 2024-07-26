resource "aws_cloudwatch_log_group" "main" {
  name = "cloudtrail/cg-trail"
}

resource "aws_cloudwatch_log_metric_filter" "main" {
  name           = "ssm_access"
  pattern        = "{ $.eventName = \"StartSession\" && $.requestParameters.target = \"${aws_instance.bastion.id}\" }"
  log_group_name = aws_cloudwatch_log_group.main.name

  metric_transformation {
    name      = "SSMAccess"
    namespace = "cg"
    value     = "1"
  }
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "cg-dashboard"
  dashboard_body = data.template_file.dashboard.rendered
}

data "template_file" "dashboard" {
  template = file("dashboard.json")

  vars = {
    metrics_namespace = aws_cloudwatch_log_metric_filter.main.metric_transformation[0].namespace
    metrics_name = aws_cloudwatch_log_metric_filter.main.metric_transformation[0].name
    instance_id = aws_instance.bastion.id
  }
}
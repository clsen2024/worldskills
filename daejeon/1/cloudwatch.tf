resource "aws_cloudwatch_dashboard" "ap" {
  dashboard_name = "seoul-eks-cluster-ds"
  dashboard_body = data.template_file.ap-dashboard.rendered
}

data "template_file" "ap-dashboard" {
  template = file("dashboard.json")

  vars = {
    cluster_name = aws_eks_cluster.ap.name
    region       = "ap-northeast-2"
  }
}

resource "aws_cloudwatch_dashboard" "us" {
  dashboard_name = "us-eks-cluster-ds"
  dashboard_body = data.template_file.us-dashboard.rendered
}

data "template_file" "us-dashboard" {
  template = file("dashboard.json")

  vars = {
    cluster_name = aws_eks_cluster.us.name
    region       = "us-east-1"
  }
}
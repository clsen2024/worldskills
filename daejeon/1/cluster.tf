# ap-northeast-2
resource "aws_eks_cluster" "ap" {
  name     = "hrdkorea-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = [aws_subnet.ap-private-a.id, aws_subnet.ap-private-b.id]
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.ap-control-plane.id]
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-default
  ]
}

resource "aws_eks_access_entry" "ap-console-allow" {
  cluster_name  = aws_eks_cluster.ap.name
  principal_arn = local.caller_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ap-console-allow" {
  cluster_name  = aws_eks_cluster.ap.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.caller_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ap-console-allow]
}

resource "aws_eks_access_entry" "ap-admin-allow" {
  cluster_name  = aws_eks_cluster.ap.name
  principal_arn = aws_iam_role.admin.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ap-admin-allow" {
  cluster_name  = aws_eks_cluster.ap.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.admin.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ap-admin-allow]
}

resource "aws_eks_addon" "ap-kube-proxy" {
  cluster_name = aws_eks_cluster.ap.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "ap-coredns" {
  cluster_name = aws_eks_cluster.ap.name
  addon_name   = "coredns"

  depends_on = [aws_eks_fargate_profile.ap-addon]
}

resource "aws_eks_addon" "ap-vpc-cni" {
  cluster_name = aws_eks_cluster.ap.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "ap-cloudwatch" {
  cluster_name         = aws_eks_cluster.ap.name
  addon_name           = "amazon-cloudwatch-observability"
  configuration_values = "{\"containerLogs\": {\"enabled\": false}}"

  depends_on = [aws_eks_fargate_profile.ap-cloudwatch]
}

resource "aws_security_group" "ap-control-plane" {
  name        = "control-plane-sg"
  description = "Allow HTTPS traffic"
  vpc_id      = aws_vpc.ap.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ap-bastion.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "tls_certificate" "ap-cluster" {
  url = aws_eks_cluster.ap.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "ap-eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.ap-cluster.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.ap-cluster.url
}

# us-east-1
resource "aws_eks_cluster" "us" {
  provider = aws.us-east-1

  name     = "hrdkorea-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = [aws_subnet.us-private-a.id, aws_subnet.us-private-b.id]
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.us-control-plane.id]
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-default
  ]
}

resource "aws_eks_access_entry" "us-console-allow" {
  provider = aws.us-east-1

  cluster_name  = aws_eks_cluster.us.name
  principal_arn = local.caller_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "us-console-allow" {
  provider = aws.us-east-1

  cluster_name  = aws_eks_cluster.us.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.caller_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.us-console-allow]
}

resource "aws_eks_access_entry" "us-admin-allow" {
  provider = aws.us-east-1

  cluster_name  = aws_eks_cluster.us.name
  principal_arn = aws_iam_role.admin.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "us-admin-allow" {
  provider = aws.us-east-1

  cluster_name  = aws_eks_cluster.us.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.admin.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.us-admin-allow]
}

resource "aws_eks_addon" "us-kube-proxy" {
  provider = aws.us-east-1

  cluster_name = aws_eks_cluster.us.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "us-coredns" {
  provider = aws.us-east-1

  cluster_name = aws_eks_cluster.us.name
  addon_name   = "coredns"

  depends_on = [aws_eks_fargate_profile.us-addon]
}

resource "aws_eks_addon" "us-vpc-cni" {
  provider = aws.us-east-1

  cluster_name = aws_eks_cluster.us.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "us-cloudwatch" {
  provider = aws.us-east-1

  cluster_name         = aws_eks_cluster.us.name
  addon_name           = "amazon-cloudwatch-observability"
  configuration_values = "{\"containerLogs\": {\"enabled\": false}}"

  depends_on = [aws_eks_fargate_profile.us-cloudwatch]
}

resource "aws_security_group" "us-control-plane" {
  provider = aws.us-east-1

  name        = "control-plane-sg"
  description = "Allow HTTPS traffic"
  vpc_id      = aws_vpc.us.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.us-bastion.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "tls_certificate" "us-cluster" {
  url = aws_eks_cluster.us.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "us-eks" {
  provider = aws.us-east-1

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.us-cluster.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.us-cluster.url
}

# global
data "aws_iam_policy_document" "cluster" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster" {
  name               = "eksClusterRole"
  assume_role_policy = data.aws_iam_policy_document.cluster.json
}

resource "aws_iam_role_policy_attachment" "cluster-default" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}
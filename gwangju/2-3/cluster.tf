resource "aws_eks_cluster" "main" {
  name     = "wsi-eks-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = [aws_subnet.private-a.id, aws_subnet.private-b.id]
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.control-plane.id]
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-default
  ]
}

resource "aws_eks_access_entry" "console-allow" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = local.caller_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "console-allow" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.caller_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.console-allow]
}

resource "aws_eks_access_entry" "admin-allow" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.admin.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin-allow" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.admin.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin-allow]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.29.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = "v1.11.1-eksbuild.4"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.app]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.16.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_security_group" "control-plane" {
  name        = "control-plane-sg"
  description = "Allow HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.cluster.url
}

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
resource "aws_eks_node_group" "app" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "wsi-app-nodegroup"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 4
    min_size     = 4
    max_size     = 4
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "node" = "app"
  }

  taint {
    key    = "node"
    value  = "app"
    effect = "NO_SCHEDULE"
  }

  launch_template {
    name    = aws_launch_template.app.name
    version = aws_launch_template.app.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.WorkerNode,
    aws_iam_role_policy_attachment.CNI,
    aws_iam_role_policy_attachment.ContainerRegistry
  ]
}

resource "aws_eks_node_group" "addon" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "wsi-addon-nodegroup"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 4
    min_size     = 4
    max_size     = 4
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "node" = "addon"
  }

  launch_template {
    name    = aws_launch_template.addon.name
    version = aws_launch_template.addon.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.WorkerNode,
    aws_iam_role_policy_attachment.CNI,
    aws_iam_role_policy_attachment.ContainerRegistry
  ]
}

resource "aws_eks_fargate_profile" "app" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "wsi-app-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  selector {
    namespace = "wsi"
    labels = {
      app = "order"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.fargate]
}

resource "aws_iam_role" "node" {
  name               = "AmazonEKSNodeRole"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_role_policy_attachment" "WorkerNode" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "CNI" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "ContainerRegistry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_launch_template" "app" {
  name = "wsi-app-nodegroup"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "wsi-app-node"
    }
  }
}

resource "aws_launch_template" "addon" {
  name = "wsi-addon-nodegroup"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "wsi-addon-node"
    }
  }
}

resource "aws_iam_role" "fargate" {
  name = "AmazonEKSFargatePodExecutionRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "fargate" {
  role       = aws_iam_role.fargate.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "fargate_logging" {
  role       = aws_iam_role.fargate.name
  policy_arn = aws_iam_policy.fluent-bit.arn
}
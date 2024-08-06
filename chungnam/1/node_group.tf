resource "aws_eks_node_group" "app" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "wsc2024-db-application-ng"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [aws_subnet.prod-app-a.id, aws_subnet.prod-app-b.id]

  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "app" = "db"
  }

  taint {
    key    = "app"
    value  = "db"
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
  node_group_name = "wsc2024-other-ng"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [aws_subnet.prod-app-a.id, aws_subnet.prod-app-b.id]

  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "app" = "other"
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
  name = "wsc2024-db-application-ng"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "wsc2024-db-application-node"
    }
  }
}

resource "aws_launch_template" "addon" {
  name = "wsc2024-other-ng"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "wsc2024-other-node"
    }
  }
}
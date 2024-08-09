# ap-northeast-2
resource "aws_eks_node_group" "ap-customer" {
  cluster_name    = aws_eks_cluster.ap.name
  node_group_name = "hrdkorea-customer-ng"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [aws_subnet.ap-private-a.id, aws_subnet.ap-private-b.id]

  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "skills/dedicated" = "customer"
  }

  launch_template {
    name    = aws_launch_template.ap-customer.name
    version = aws_launch_template.ap-customer.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.WorkerNode,
    aws_iam_role_policy_attachment.CNI,
    aws_iam_role_policy_attachment.ContainerRegistry
  ]
}

resource "aws_eks_node_group" "ap-product" {
  cluster_name    = aws_eks_cluster.ap.name
  node_group_name = "hrdkorea-product-ng"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [aws_subnet.ap-private-a.id, aws_subnet.ap-private-b.id]

  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "skills/dedicated" = "product"
  }

  launch_template {
    name    = aws_launch_template.ap-product.name
    version = aws_launch_template.ap-product.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.WorkerNode,
    aws_iam_role_policy_attachment.CNI,
    aws_iam_role_policy_attachment.ContainerRegistry
  ]
}

resource "aws_eks_node_group" "ap-order" {
  cluster_name    = aws_eks_cluster.ap.name
  node_group_name = "hrdkorea-order-ng"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [aws_subnet.ap-private-a.id, aws_subnet.ap-private-b.id]

  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "skills/dedicated" = "order"
  }

  launch_template {
    name    = aws_launch_template.ap-order.name
    version = aws_launch_template.ap-order.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.WorkerNode,
    aws_iam_role_policy_attachment.CNI,
    aws_iam_role_policy_attachment.ContainerRegistry
  ]
}

resource "aws_launch_template" "ap-customer" {
  name = "hrdkorea-customer-ng"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "hrdkorea-customer-ng"
    }
  }
}

resource "aws_launch_template" "ap-product" {
  name = "hrdkorea-product-ng"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "hrdkorea-product-ng"
    }
  }
}

resource "aws_launch_template" "ap-order" {
  name = "hrdkorea-order-ng"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "hrdkorea-order-ng"
    }
  }
}

resource "aws_eks_fargate_profile" "ap-addon" {
  cluster_name           = aws_eks_cluster.ap.name
  fargate_profile_name   = "hrdkorea-addon-profile"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = [aws_subnet.ap-private-a.id, aws_subnet.ap-private-b.id]

  selector {
    namespace = "hrdkorea"
  }

  depends_on = [aws_iam_role_policy_attachment.fargate]
}

resource "aws_eks_fargate_profile" "ap-coredns" {
  cluster_name           = aws_eks_cluster.ap.name
  fargate_profile_name   = "hrdkorea-coredns-profile"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = [aws_subnet.ap-private-a.id, aws_subnet.ap-private-b.id]

  selector {
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-dns"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.fargate]
}

resource "aws_eks_fargate_profile" "ap-cloudwatch" {
  cluster_name           = aws_eks_cluster.ap.name
  fargate_profile_name   = "hrdkorea-cloudwatch-profile"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = [aws_subnet.ap-private-a.id, aws_subnet.ap-private-b.id]

  selector {
    namespace = "amazon-cloudwatch"
  }

  depends_on = [aws_iam_role_policy_attachment.fargate]
}

# us-east-1
resource "aws_eks_node_group" "us-customer" {
  provider = aws.us-east-1

  cluster_name    = aws_eks_cluster.us.name
  node_group_name = "hrdkorea-customer-ng"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [aws_subnet.us-private-a.id, aws_subnet.us-private-b.id]

  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "skills/dedicated" = "customer"
  }

  launch_template {
    name    = aws_launch_template.us-customer.name
    version = aws_launch_template.us-customer.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.WorkerNode,
    aws_iam_role_policy_attachment.CNI,
    aws_iam_role_policy_attachment.ContainerRegistry
  ]
}

resource "aws_eks_node_group" "us-product" {
  provider = aws.us-east-1

  cluster_name    = aws_eks_cluster.us.name
  node_group_name = "hrdkorea-product-ng"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [aws_subnet.us-private-a.id, aws_subnet.us-private-b.id]

  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "skills/dedicated" = "product"
  }

  launch_template {
    name    = aws_launch_template.us-product.name
    version = aws_launch_template.us-product.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.WorkerNode,
    aws_iam_role_policy_attachment.CNI,
    aws_iam_role_policy_attachment.ContainerRegistry
  ]
}

resource "aws_eks_node_group" "us-order" {
  provider = aws.us-east-1

  cluster_name    = aws_eks_cluster.us.name
  node_group_name = "hrdkorea-order-ng"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [aws_subnet.us-private-a.id, aws_subnet.us-private-b.id]

  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "skills/dedicated" = "order"
  }

  launch_template {
    name    = aws_launch_template.us-order.name
    version = aws_launch_template.us-order.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.WorkerNode,
    aws_iam_role_policy_attachment.CNI,
    aws_iam_role_policy_attachment.ContainerRegistry
  ]
}

resource "aws_launch_template" "us-customer" {
  provider = aws.us-east-1

  name = "hrdkorea-customer-ng"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "hrdkorea-customer-ng"
    }
  }
}

resource "aws_launch_template" "us-product" {
  provider = aws.us-east-1

  name = "hrdkorea-product-ng"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "hrdkorea-product-ng"
    }
  }
}

resource "aws_launch_template" "us-order" {
  provider = aws.us-east-1

  name = "hrdkorea-order-ng"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "hrdkorea-order-ng"
    }
  }
}

resource "aws_eks_fargate_profile" "us-addon" {
  provider = aws.us-east-1

  cluster_name           = aws_eks_cluster.us.name
  fargate_profile_name   = "hrdkorea-addon-profile"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = [aws_subnet.us-private-a.id, aws_subnet.us-private-b.id]

  selector {
    namespace = "hrdkorea"
  }

  depends_on = [aws_iam_role_policy_attachment.fargate]
}

resource "aws_eks_fargate_profile" "us-coredns" {
  provider = aws.us-east-1

  cluster_name           = aws_eks_cluster.us.name
  fargate_profile_name   = "hrdkorea-coredns-profile"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = [aws_subnet.us-private-a.id, aws_subnet.us-private-b.id]

  selector {
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-dns"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.fargate]
}

resource "aws_eks_fargate_profile" "us-cloudwatch" {
  provider = aws.us-east-1

  cluster_name           = aws_eks_cluster.us.name
  fargate_profile_name   = "hrdkorea-cloudwatch-profile"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = [aws_subnet.us-private-a.id, aws_subnet.us-private-b.id]

  selector {
    namespace = "amazon-cloudwatch"
  }

  depends_on = [aws_iam_role_policy_attachment.fargate]
}

# global
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

resource "aws_iam_role_policy_attachment" "CloudWatchAgent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node.name
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
resource "aws_opensearch_domain" "main" {
  domain_name    = "wsi-opensearch"
  engine_version = "OpenSearch_2.13"

  cluster_config {
    dedicated_master_enabled = true
    dedicated_master_type    = "r5.large.search"
    dedicated_master_count   = 3

    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 2
    }

    instance_type  = "r5.large.search"
    instance_count = 2
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = local.username
      master_user_password = local.password
    }
  }

  access_policies = data.aws_iam_policy_document.opensearch.json

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }
}

data "aws_iam_policy_document" "opensearch" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = ["arn:aws:es:ap-northeast-2:${local.account_id}:domain/wsi-opensearch/*"]
  }
}

resource "opensearch_roles_mapping" "app" {
  role_name = "all_access"
  backend_roles = [
    aws_iam_role.app.arn
  ]
}
# Monitoring Infrastructure using Terraform + Helm Provider
# This implements Option 2: Best of both worlds approach

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Create CloudWatch IAM role for monitoring
resource "aws_iam_role" "cloudwatch_agent_role" {
  name = "CloudWatchAgentRole-${aws_eks_cluster.cluster.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
          }
        }
      }
    ]
  })
}

# Attach CloudWatch policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.cloudwatch_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/eks/${aws_eks_cluster.cluster.name}/application"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/aws/eks/${aws_eks_cluster.cluster.name}/system"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "error_logs" {
  name              = "/aws/eks/${aws_eks_cluster.cluster.name}/errors"
  retention_in_days = 30
}

# Deploy Prometheus Stack via Terraform
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/../monitoring/helm-values/prometheus-values.yaml")
  ]

  depends_on = [aws_eks_cluster.cluster]
}

# Deploy CloudWatch Agent via Terraform
resource "helm_release" "cloudwatch_agent" {
  name       = "cloudwatch-agent"
  repository = "https://aws.github.io/amazon-cloudwatch-agent"
  chart      = "amazon-cloudwatch-agent"
  namespace  = "amazon-cloudwatch"
  create_namespace = true

  values = [
    file("${path.module}/../monitoring/helm-values/cloudwatch-values.yaml")
  ]

  depends_on = [aws_eks_cluster.cluster]
}

# Deploy your application via Terraform
resource "helm_release" "zomato_clone" {
  name       = "zomato-clone"
  chart      = "${path.module}/../helm/zomato-clone"
  namespace  = "default"
  create_namespace = true

  values = [
    file("${path.module}/../monitoring/helm-values/app-values.yaml")
  ]

  depends_on = [aws_eks_cluster.cluster]
}

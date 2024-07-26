provider "aws" {
  region = local.region
}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}


data "terraform_remote_state" "cluster_hub" {
  backend = "local"

  config = {
    path = "${path.module}/../hub/terraform.tfstate"
  }
}

################################################################################
# Kubernetes Access for Hub Cluster
################################################################################

provider "kubernetes" {
  host                   = data.terraform_remote_state.cluster_hub.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster_hub.outputs.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.cluster_hub.outputs.cluster_name, "--region", data.terraform_remote_state.cluster_hub.outputs.cluster_region]
  }
  alias = "hub"
}

locals {
  name        = "hub-spoke-${terraform.workspace}"
  environment = terraform.workspace
  region      = var.region

  cluster_version = var.kubernetes_version

  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  gitops_addons_url      = "${var.gitops_addons_org}/${var.gitops_addons_repo}"
  gitops_addons_basepath = var.gitops_addons_basepath
  gitops_addons_path     = var.gitops_addons_path
  gitops_addons_revision = var.gitops_addons_revision

  gitops_workload_org      = var.gitops_workload_org
  gitops_workload_repo     = var.gitops_workload_repo
  gitops_workload_basepath = var.gitops_workload_basepath
  gitops_workload_path     = var.gitops_workload_path
  gitops_workload_revision = var.gitops_workload_revision
  gitops_workload_url      = "${local.gitops_workload_org}/${local.gitops_workload_repo}"


  tags = {}
}

################################################################################
# SETUP HUB TO CONNECT TO EXISTING TF CLUSTER
################################################################################

################################################################################
# Kubernetes Access for Hub Cluster
################################################################################

data "aws_eks_cluster" "iac-admin-3" {
  name = "iac-admin-3"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.iac-admin-3.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.iac-admin-3.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.iac-admin-3.name, "--region", local.region]
  }
  alias = "spoke"
}


################################################################################
# GitOps Bridge: Bootstrap for Hub Cluster
################################################################################
module "gitops_bridge_bootstrap_hub" {
  source = "github.com/gitops-bridge-dev/gitops-bridge-argocd-bootstrap-terraform?ref=v2.0.0"

  # The ArgoCD remote cluster secret is deploy on hub cluster not on spoke clusters
  providers = {
    kubernetes = kubernetes.hub
  }

  install = false # We are not installing argocd via helm on hub cluster
  cluster = {
    cluster_name = data.aws_eks_cluster.iac-admin-3.name
    environment  = "DEV"
    metadata     = merge(
    {
      aws_cluster_name = data.aws_eks_cluster.iac-admin-3.name
      aws_region       = local.region
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = data.aws_vpc.selected.id
    },
    {
      addons_repo_url      = local.gitops_addons_url
      addons_repo_basepath = local.gitops_addons_basepath
      addons_repo_path     = local.gitops_addons_path
      addons_repo_revision = local.gitops_addons_revision
    },
    {
      workload_repo_url      = local.gitops_workload_url
      workload_repo_basepath = local.gitops_workload_basepath
      workload_repo_path     = local.gitops_workload_path
      workload_repo_revision = local.gitops_workload_revision
    }
    )

    addons = merge(
    { kubernetes_version = data.aws_eks_cluster.iac-admin-3.version },
    { aws_cluster_name = data.aws_eks_cluster.iac-admin-3.name }
    )

    server       = data.aws_eks_cluster.iac-admin-3.endpoint
    config       = <<-EOT
      {
        "tlsClientConfig": {
          "insecure": false,
          "caData" : "${data.aws_eks_cluster.iac-admin-3.certificate_authority[0].data}"
        },
        "awsAuthConfig" : {
          "clusterName": "${data.aws_eks_cluster.iac-admin-3.name}",
          "roleARN": "${aws_iam_role.spoke.arn}"
        }
      }
    EOT
  }
}

################################################################################
# ArgoCD EKS Access
################################################################################
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole","sts:TagSession"]
    principals {
      type        = "AWS"
      identifiers = [data.terraform_remote_state.cluster_hub.outputs.argocd_iam_role_arn]
    }
  }
}
resource "aws_iam_role" "spoke" {
  name               = "${local.name}-argocd-spoke"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
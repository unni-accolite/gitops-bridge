variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-02a087b9c08c5c165" #id of the terraform scratch vpc
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Route 53 domain name"
  type        = string
  default     = "onelogin-deviac.com"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    enable_aws_load_balancer_controller = true
    enable_metrics_server               = true
    enable_argocd = true
    enable_external_dns                 = true
    enable_aws_load_balancer_controller = true
    enable_aws_argocd_ingress           = true
    enable_aws_privateca_issuer         = true
  }
}

# Addons Git
variable "gitops_addons_org" {
  description = "Git repository org/user contains for addons"
  type        = string
  default     = "https://github.com/unni-accolite/"
}

variable "gitops_addons_repo" {
  description = "Git repository contains for addons"
  type        = string
  default     = "gitops-bridge-argocd-control-plane-template"
}

variable "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  type        = string
  default     = "main"
}

variable "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  type        = string
  default     = ""
}

variable "gitops_addons_path" {
  description = "Git repository path for addons"
  type        = string
  default     = "bootstrap/control-plane/addons"
}

# Workloads Git
variable "gitops_workload_org" {
  description = "Git repository org/user contains for workload"
  type        = string
  default     = "https://github.com/argoproj"
}
variable "gitops_workload_repo" {
  description = "Git repository contains for workload"
  type        = string
  default     = "argocd-example-apps"
}
variable "gitops_workload_revision" {
  description = "Git repository revision/branch/ref for workload"
  type        = string
  default     = "master"
}
variable "gitops_workload_basepath" {
  description = "Git repository base path for workload"
  type        = string
  default     = ""
}
variable "gitops_workload_path" {
  description = "Git repository path for workload"
  type        = string
  default     = "helm-guestbook"
}
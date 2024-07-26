vpc_id = "vpc-02a087b9c08c5c165" #id of the terraform scratch vpc
region = "us-west-2"
kubernetes_version = "1.28"
addons = {
  enable_aws_load_balancer_controller = false
  enable_metrics_server               = false
  # Disable argocd on spoke clusters
  enable_argocd = false
}
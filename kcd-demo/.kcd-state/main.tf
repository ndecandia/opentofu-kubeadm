terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    }
    backend "kubernetes" {
    config_path   = "~/.kube/config"
    secret_suffix = "tfstate"
    namespace     = "default"
    }
}

# kubectl get secret tfstate-default-tfstate -o jsonpath="{.data.tfstate}" | base64 -d | gzip -d -


provider "kubernetes" {
  config_path    = "~/.kube/config"
}

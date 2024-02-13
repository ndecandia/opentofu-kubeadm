terraform {
  required_providers {
    vsphere = {
      version = "~> 2.0"
    }
    external = {
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

provider "vsphere" {
  vsphere_server       = var.vsphere_server
  user                 = var.vsphere_user
  password             = var.vsphere_password
  allow_unverified_ssl = var.vsphere_allow_unverified_ssl
}

provider "kubernetes" {
  host                   = data.external.k8s_server.result.server
  client_certificate     = data.external.k8s_client_crt.result.client_crt
  client_key             = data.external.k8s_client_key.result.client_key
  cluster_ca_certificate = data.external.k8s_ca.result.cert_ca
}

provider "helm" {
  kubernetes {
    host                   = data.external.k8s_server.result.server
    client_certificate     = data.external.k8s_client_crt.result.client_crt
    client_key             = data.external.k8s_client_key.result.client_key
    cluster_ca_certificate = data.external.k8s_ca.result.cert_ca
  }
}
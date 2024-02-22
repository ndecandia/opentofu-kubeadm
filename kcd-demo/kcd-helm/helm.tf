provider "helm" {
  kubernetes {
  config_path    = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "helloworld_namespace" {
  metadata {
    labels = {
      kcd = "brasil"
    }
    name = "hello-world"
  }
}


resource "helm_release" "ahoy" {
  name       = "ahoy"

  repository = "https://helm.github.io/examples"
  chart      = "hello-world"
  namespace = kubernetes_namespace.helloworld_namespace.metadata[0].name

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

}

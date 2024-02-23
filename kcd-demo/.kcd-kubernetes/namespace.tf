

resource "kubernetes_namespace" "brasil_namespace" {
  metadata {
    labels = {
      kcd = "brasil"
    }
    name = "kcd-brasil"
  }
}

output "namespace_created" {
  value = kubernetes_namespace.brasil_namespace.metadata[0].name
}


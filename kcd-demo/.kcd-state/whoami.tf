resource "kubernetes_deployment" "whoami_deployment" {
  metadata {
    name = "whoami-deployment"
    namespace = kubernetes_namespace.brasil_namespace.metadata[0].name
    labels = {
      App = "whoami"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        App = "whoami"
      }
    }

    template {
      metadata {
        labels = {
          App = "whoami"
        }
      }

      spec {
        container {
          image = "r.deso.tech/whoami/whoami:latest"
          name  = "whoami"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "whoami_service" {
  metadata {
    name = "whoami-service"
    namespace = kubernetes_namespace.brasil_namespace.metadata[0].name

  }
  spec {
    selector = {
      App = "whoami"
    }

    type = "LoadBalancer"

    port {
      name = "http"
      port = 80
      target_port = 80
      node_port = 32000
      protocol = "TCP"
    }
  }
}


output "whoamiloadbalancer_ip" {
  value = kubernetes_service.whoami_service.status[0].load_balancer[0].ingress[0].ip
}

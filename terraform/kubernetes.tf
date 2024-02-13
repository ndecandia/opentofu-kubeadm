resource "helm_release" "cilium" {
  name       = "cilium"

  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.15.0"

  set {
    name  = "namespace"
    value = "kube-system"
  }

   depends_on = [ data.external.k8s_server, data.external.k8s_client_crt, data.external.k8s_client_key, data.external.k8s_ca]

}

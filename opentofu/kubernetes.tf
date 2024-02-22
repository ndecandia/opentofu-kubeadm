resource "helm_release" "cilium" {
  name       = "cilium"

  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.15.0"
  namespace  = "kube-system"

  set {
    name  = "l2announcements.enabled"
    value = "true"
  }

  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }

  set {
    name  = "externalIPs.enabled"
    value = "true"
  }

   depends_on = [ data.external.k8s_server, data.external.k8s_client_crt, data.external.k8s_client_key, data.external.k8s_ca]

}


resource "kubernetes_namespace" "longhorn_namespace" {
  metadata {
    name = "longhorn-system"
  }
}

resource "helm_release" "longhorn" {
  name       = "longhorn"

  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.6.0"
  namespace = kubernetes_namespace.longhorn_namespace.metadata[0].name

   depends_on = [ helm_release.cilium ]

}

resource "kubernetes_manifest" "ciliumloadbalancerippool" {
  manifest = {
    "apiVersion" = "cilium.io/v2alpha1"
    "kind"       = "CiliumLoadBalancerIPPool"
    "metadata" = {
      "name"      = "pool"
    }
    "spec" = {
      "blocks" = [
        {
          "start" = "10.10.39.128"
          "stop" = "10.10.39.150"
        }

      ]
    }
  }
}

resource "kubernetes_manifest" "ciliuml2announcementpolicy" {
  manifest = {
    "apiVersion" = "cilium.io/v2alpha1"
    "kind"       = "CiliumL2AnnouncementPolicy"

  "metadata" = {
    "name" = "policy1"
  }

  "spec" = {
    "externalIPs"       = "true"
    "loadBalancerIPs"   = "true"
  }
}
}
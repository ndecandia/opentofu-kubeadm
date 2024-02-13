output "kubeconfig" {
  value = base64decode(data.external.kubeconfig.result.content)
}

output "k8s_server" {
  value = data.external.k8s_server.result.server
}

output "k8s_ca" {
  value = data.external.k8s_ca.result.cert_ca
}

output "k8s_client_crt" {
  value = data.external.k8s_client_crt.result.client_crt
}

output "k8s_client_key" {
  value = data.external.k8s_client_key.result.client_key
}
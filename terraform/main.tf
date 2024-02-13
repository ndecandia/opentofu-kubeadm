
data "vsphere_datacenter" "this" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "this" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_compute_cluster" "this" {
  name          = var.vsphere_compute_cluster
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_network" "this" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_folder" "this" {
  path = var.vsphere_folder
}

data "vsphere_virtual_machine" "node_template" {
  datacenter_id = data.vsphere_datacenter.this.id
  name          = "${data.vsphere_folder.this.path}/node"
}

locals {
  ipv4_gateway = cidrhost(var.vsphere_network_cidr, 1)
}

resource "vsphere_virtual_machine" "control_plane" {
  name             = format("%s%02d", var.control_plane_hostname, 1)
  resource_pool_id = data.vsphere_compute_cluster.this.resource_pool_id
  datastore_id     = data.vsphere_datastore.this.id
  num_cpus         = var.control_plane_num_cpus
  memory           = var.control_plane_memory * 1024
  guest_id         = data.vsphere_virtual_machine.node_template.guest_id
  folder           = data.vsphere_folder.this.path

  network_interface {
    network_id = data.vsphere_network.this.id
  }

  disk {
    label = "disk0"
    size  = var.control_plane_disk_size
  }

  clone {
    # linked_clone  = var.linked_clone
    template_uuid = data.vsphere_virtual_machine.node_template.uuid
    customize {
      linux_options {
        host_name = format("%s%02d", var.control_plane_hostname, 1)
        domain    = var.domain
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_network_cidr, 11)
        ipv4_netmask = 24
      }
      ipv4_gateway    = local.ipv4_gateway
      dns_server_list = var.dns_servers
    }
  }

  connection {
    type        = "ssh"
    user        = var.user
    private_key = var.private_key
    host        = self.default_ip_address
  }

  provisioner "file" {
    destination = "/tmp/kubeadm-init.yaml"
    content = templatefile("${path.module}/templates/kubeadm_init.yaml.tftpl", {
      pod_subnet             = var.pod_subnet
      cluster_name           = var.cluster_name
      bootstrap_token_id     = var.bootstrap_token.id
      bootstrap_token_secret = var.bootstrap_token.secret
      certificate_key        = var.certificate_key
      cri_socket             = var.cri_socket
    })
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install_tools.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = ["sudo kubeadm init --upload-certs --config /tmp/kubeadm-init.yaml"]
  }
}

data "external" "cert_hash" {
  program = [
    "sh",
    "-c",
    "ssh ${var.user}@${vsphere_virtual_machine.control_plane.default_ip_address} < '${path.module}/scripts/get_cert_fingerprint.sh' | tail -n1"
  ]
}

data "external" "k8s_server" {
  program = ["ssh", "-o", "StrictHostKeyChecking=no", "${var.user}@${vsphere_virtual_machine.control_plane.default_ip_address}", <<EOF
  server=$(sudo kubectl config view  --kubeconfig /etc/kubernetes/admin.conf --output 'jsonpath={..server}'; echo)
  jq -n --arg server "$server" '{"server":$server}'
  EOF
  ]
}

data "external" "k8s_ca" {
  program = ["ssh", "-o", "StrictHostKeyChecking=no", "${var.user}@${vsphere_virtual_machine.control_plane.default_ip_address}", <<EOF
  cert_ca=$(sudo kubectl config view --raw --kubeconfig /etc/kubernetes/admin.conf --output 'jsonpath={..certificate-authority-data}'| base64 -d)
  jq -n --arg cert_ca "$cert_ca" '{"cert_ca":$cert_ca}'
  EOF
  ]
}

data "external" "k8s_client_crt" {
  program = ["ssh", "-o", "StrictHostKeyChecking=no", "${var.user}@${vsphere_virtual_machine.control_plane.default_ip_address}", <<EOF
  client_crt=$(sudo kubectl config view --raw --kubeconfig /etc/kubernetes/admin.conf --output 'jsonpath={..client-certificate-data}'| base64 -d)
  jq -n --arg client_crt "$client_crt" '{"client_crt":$client_crt}'
  EOF
  ]
}

data "external" "k8s_client_key" {
  program = ["ssh", "-o", "StrictHostKeyChecking=no", "${var.user}@${vsphere_virtual_machine.control_plane.default_ip_address}", <<EOF
  client_key=$(sudo kubectl config view --raw --kubeconfig /etc/kubernetes/admin.conf --output 'jsonpath={..client-key-data}'| base64 -d)
  jq -n --arg client_key "$client_key" '{"client_key":$client_key}'
  EOF
  ]
}

data "external" "kubeconfig" {
  program = [
    "sh",
    "-c",
    "ssh ${var.user}@${vsphere_virtual_machine.control_plane.default_ip_address} < '${path.module}/scripts/get_kubeconfig.sh' | tail -n1"
  ]
}

resource "vsphere_virtual_machine" "worker" {
  count = var.worker_node_count

  name             = format("%s%02d", var.worker_hostname, count.index + 1)
  resource_pool_id = data.vsphere_compute_cluster.this.resource_pool_id
  datastore_id     = data.vsphere_datastore.this.id
  num_cpus         = var.worker_num_cpus
  memory           = var.worker_memory * 1024
  guest_id         = data.vsphere_virtual_machine.node_template.guest_id
  folder           = data.vsphere_folder.this.path

  network_interface {
    network_id = data.vsphere_network.this.id
  }

  disk {
    label = "disk0"
    size  = var.worker_disk_size
  }

  clone {
    # linked_clone  = var.linked_clone
    template_uuid = data.vsphere_virtual_machine.node_template.uuid
    customize {
      linux_options {
        host_name = format("%s%02d", var.worker_hostname, count.index + 1)
        domain    = var.domain
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_network_cidr, 21 + count.index)
        ipv4_netmask = 24
      }
      ipv4_gateway    = local.ipv4_gateway
      dns_server_list = var.dns_servers
    }
  }

  connection {
    type        = "ssh"
    user        = var.user
    private_key = var.private_key
    host        = self.default_ip_address
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install_tools.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = ["sudo kubeadm join ${vsphere_virtual_machine.control_plane.default_ip_address}:6443 --token ${var.bootstrap_token.id}.${var.bootstrap_token.secret} --discovery-token-ca-cert-hash sha256:${data.external.cert_hash.result.fingerprint}"]
  }
}

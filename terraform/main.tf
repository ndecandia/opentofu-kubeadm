terraform {
  required_providers {
    vsphere = {
      version = "~> 2.0"
    }
    external = {
      version = "~> 2.0"
    }
  }
}

provider "vsphere" {
  vsphere_server       = var.vsphere_server
  user                 = var.vsphere_user
  password             = var.vsphere_password
  allow_unverified_ssl = var.vsphere_allow_unverified_ssl
}

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

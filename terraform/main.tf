terraform {
  required_providers {
    vsphere = {
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
  count = var.control_plane_node_count

  name             = format("%s%02d", var.control_plane_hostname, count.index + 1)
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
        host_name = format("%s%02d", var.control_plane_hostname, count.index + 1)
        domain    = var.domain
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_network_cidr, 11 + count.index)
        ipv4_netmask = 24
      }
      ipv4_gateway    = local.ipv4_gateway
      dns_server_list = var.dns_servers
    }
  }
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
}

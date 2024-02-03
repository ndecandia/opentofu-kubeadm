packer {
  required_plugins {
    vsphere = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

locals {
  network_cidr = "${var.vsphere_network_address}/${var.vsphere_network_netmask}"
}

source "vsphere-iso" "template" {
  # Connection Configuration
  vcenter_server      = var.vsphere_server
  username            = var.vsphere_user
  password            = var.vsphere_password
  datacenter          = var.vsphere_datacenter
  insecure_connection = var.vsphere_insecure_connection

  convert_to_template = true

  # Boot Configuration
  boot_wait    = "2s"
  boot_command = ["<enter><wait2><enter><wait><f6><esc><wait>", "autoinstall<wait2>", "<wait><enter>"]

  # Hardware Configuration
  CPUs            = var.num_cpus
  RAM             = var.memory * 1024
  RAM_reserve_all = true
  NestedHV        = true
  guest_os_type   = "ubuntu64Guest"

  # Create Configuration
  network_adapters {
    network_card = "vmxnet3"
    network      = var.vsphere_network
  }

  disk_controller_type = ["pvscsi"]

  storage {
    disk_size             = var.disk_size * 1024
    disk_thin_provisioned = true
  }

  # CDRom Configuration
  remove_cdrom = true
  cd_label     = "cidata"
  cd_content = {
    "meta-data" = ""
    "user-data" = templatefile("${path.root}/templates/autoinstall.pkrtpl.hcl", {
      ssh_authorized_keys = var.ssh_authorized_keys
      dns_servers         = var.dns_servers
      ipv4_address        = "${cidrhost(local.network_cidr, 10)}/${var.vsphere_network_netmask}"
      ipv4_gateway        = cidrhost(local.network_cidr, 1)
      hostname            = "node"
      user                = var.user
      user_full_name      = var.user_full_name
    })
  }

  # ISO Configuration
  iso_url      = "https://releases.ubuntu.com/${var.ubuntu_lts_version}/ubuntu-${var.ubuntu_lts_version}-live-server-amd64.iso"
  iso_checksum = "file:https://releases.ubuntu.com/${var.ubuntu_lts_version}/SHA256SUMS"

  # Location Configuration
  folder    = var.vsphere_folder
  cluster   = var.vsphere_compute_cluster
  datastore = var.vsphere_datastore
  vm_name   = "node"

  # Communicator Configuration
  communicator = "none"

  # Shutdown Configuration
  disable_shutdown = true
  shutdown_timeout = "1h"
}

build {
  name = "template"
  sources = [
    "source.vsphere-iso.template"
  ]
}

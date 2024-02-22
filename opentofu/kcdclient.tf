resource "vsphere_virtual_machine" "kcd-brasil" {
  name             = "kcd-brasil"
  resource_pool_id = data.vsphere_compute_cluster.this.resource_pool_id
  datastore_id     = data.vsphere_datastore.this.id
  num_cpus         = 4
  memory           = 4096
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
        host_name = "kcd-brasil"
        domain    = var.domain
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_network_cidr, 100)
        ipv4_netmask = 24
      }
      ipv4_gateway    = local.ipv4_gateway
      dns_server_list = var.dns_servers
    }
  }

}
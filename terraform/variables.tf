variable "vsphere_server" {
  type        = string
  description = "vSphere server"
  default     = "vcsa.desotech.local"
}

variable "vsphere_user" {
  type        = string
  description = "vSphere user"
  default     = "terraform.sa@desotech.local"
}

variable "vsphere_password" {
  type        = string
  description = "vSphere password"
  sensitive   = true
}

variable "vsphere_allow_unverified_ssl" {
  type        = bool
  description = "Skip verification of the server's TLS certificate"
  default     = true
}

variable "vsphere_datacenter" {
  type        = string
  description = "Name of the vSphere datacenter"
  default     = "Aruba"
}

variable "vsphere_datastore" {
  type        = string
  description = "Name of the vSphere datastore"
  default     = "vsanDatastore"
}

variable "vsphere_compute_cluster" {
  type        = string
  description = "Name of the vSphere compute cluster"
  default     = "IBM"
}

variable "vsphere_folder" {
  type        = string
  description = "Folder to create and place resources in"
  default     = "KCD Brasil"
}

variable "vsphere_network" {
  type        = string
  description = "Name of the vSphere network"
  default     = "kcd-brasil"
}

variable "vsphere_network_cidr" {
  type        = string
  description = "CIDR of the vSphere network"
  default     = "10.10.39.0/24"
}

variable "control_plane_hostname" {
  type        = string
  description = "Base hostname for control plane nodes"
  default     = "controlplane"
}

variable "control_plane_node_count" {
  type        = number
  description = "Number of control plane nodes"
  default     = 3

  validation {
    condition     = var.control_plane_node_count >= 1 && (var.control_plane_node_count % 2 == 1)
    error_message = "Number of control plane nodes must be equal to or greater than 1 and it must also be an odd number."
  }
}

variable "control_plane_num_cpus" {
  type        = number
  description = "Number of vCPU for control plane nodes"
  default     = 2

  validation {
    condition     = var.control_plane_num_cpus >= 2
    error_message = "The number of vCPUs for control plane nodes must be greather than or equal to 2."
  }
}

variable "control_plane_memory" {
  type        = number
  description = "Amount of memory for control plane nodes, in GiB"
  default     = 2

  validation {
    condition     = var.control_plane_memory >= 2
    error_message = "The amount of memory for control plane nodes must be greather than or equal to 2."
  }
}

variable "control_plane_disk_size" {
  type        = number
  description = "Amount of disk space for control plane nodes, in GiB."
  default     = 30

  validation {
    condition     = var.control_plane_disk_size >= 16
    error_message = "The control plane nodes' disk size must be greater than or equal to 16."
  }
}

variable "worker_hostname" {
  type        = string
  description = "Base hostname for worker nodes"
  default     = "worker"
}

variable "worker_node_count" {
  type        = number
  description = "Number of worker nodes"
  default     = 1

  validation {
    condition     = var.worker_node_count >= 1
    error_message = "Number of worker nodes must be equal to or greater than 1."
  }
}

variable "worker_num_cpus" {
  type        = number
  description = "Number of vCPU for worker nodes"
  default     = 2

  validation {
    condition     = var.worker_num_cpus >= 2
    error_message = "The number of vCPUs for worker nodes must be greather than or equal to 2."
  }
}

variable "worker_memory" {
  type        = number
  description = "Amount of memory for worker nodes, in GiB"
  default     = 2

  validation {
    condition     = var.worker_memory >= 2
    error_message = "The amount of memory for worker nodes must be greather than or equal to 2."
  }
}

variable "worker_disk_size" {
  type        = number
  description = "Amount of disk space for worker nodes, in GiB."
  default     = 30

  validation {
    condition     = var.worker_disk_size >= 16
    error_message = "The worker nodes' disk size must be greater than or equal to 16."
  }
}

variable "dns_servers" {
  type        = list(string)
  description = "List of DNS servers to assign to nodes"
  default     = ["1.1.1.1", "1.0.0.1"]
}

variable "domain" {
  type        = string
  description = "Search domain to assign to nodes"
  default     = "kcdbrazil.internal"
}

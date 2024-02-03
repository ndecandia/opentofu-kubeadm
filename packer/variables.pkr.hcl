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

variable "vsphere_insecure_connection" {
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

variable "vsphere_network" {
  type        = string
  description = "Name of the vSphere network"
  default     = "kcd-brasil"
}

variable "vsphere_network_address" {
  type        = string
  description = "Network address for the selected vsphere network"
  default     = "10.10.39.0"
}

variable "vsphere_network_netmask" {
  type        = number
  description = "Number of bits forming the network mask for the selected vsphere network"
  default     = 24

  validation {
    condition     = var.vsphere_network_netmask >= 16 && var.vsphere_network_netmask <= 24
    error_message = "The network mask must be between 16 and 24."
  }
}

variable "vsphere_folder" {
  type        = string
  description = "Folder to create and place resources in"
  default     = "KCD Brasil"
}

variable "ubuntu_lts_version" {
  type        = string
  description = "Ubuntu version to fetch from the Ubuntu website"
  default     = "20.04.6"
}

variable "num_cpus" {
  type        = number
  description = "Number of virtual CPUs"
  default     = 2
}

variable "memory" {
  type        = number
  description = "Amount of memory, in GiB"
  default     = 4
}

variable "disk_size" {
  type        = number
  description = "Amount of storage, in GiB"
  default     = 30
}

variable "dns_servers" {
  type    = list(string)
  default = ["1.1.1.1", "1.0.0.1"]
}

variable "ssh_authorized_keys" {
  type = list(string)
  default = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBuI/gJxTkggs2CUZ6UmhKTUJDIOoYffdlWkAL041m2O",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDnG32ZgM0SeG+7MIw1/FMdld3G6fGZKyJURidQs9/Ewa5iu0PpOSgMHx31cuZ8czbphWE3lz+YI3YukPo1gmqqDI1MdJPkv+57ouq6MvMocH/wGbtB+sK7RGrHQ4nfDcxovWrAteZcsrafjIJLNayPkwFGIhuMee8EIvGI7z7OxkbpSMUm/9bgTsH4miS/vkLZhLjtZJMJEzvA1SO9hcAPIHNM+RX+ATZciCaKi7LgONeq9zDwJezoNiGRqUkoxCJJU5k8owAr2DN12hJNDTW/+u8oF+a4Uaqt0Fkr4C6UYfOeCYCGi0r3xqMOUOVXNrhZtnYshLuO73VkL+wpXXGh",
  ]
}

variable "user" {
  type        = string
  description = "Initial user for the machine"
  default     = "hermedia"
}

variable "user_full_name" {
  type        = string
  description = "Full name for the initial user (GECOS field)"
  default     = "Nicola Marco Decandia"
}

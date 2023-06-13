# Proxmox Full-Clone
# ---
# Create a new VM from a clone

variable "worker_nodes" {
  type    = number
  default = 2
}

variable "master_nodes" {
  type    = number
  default = 3
}

resource "proxmox_vm_qemu" "worker" {
  count = var.worker_nodes

  # VM General Settings
  target_node = "proxmox"
  vmid        = "20${count.index + 1}"
  name        = "k3s-w0${count.index + 1}"
  desc        = "Kubernetes Worker Node ${count.index + 1}"

  # VM Advanced General Settings
  onboot = true

  # VM OS Settings
  clone = "ubuntu-server-focal"

  # VM System Settings
  agent = 1

  # VM CPU Settings
  cores   = 2
  sockets = 1
  cpu     = "host"

  # VM Memory Settings
  memory = 8192

  # VM Network Settings
  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # VM Cloud-Init Settings
  os_type = "cloud-init"

  # (Optional) IP Address and Gateway
  #ipconfig0 = "ip=192.168.1.125/16,gw=192.168.1.1"
  nameserver = "192.168.1.2"

  # (Optional) Default User
  # ciuser = "your-username"

  # (Optional) Add your SSH KEY
  # sshkeys = <<EOF
  # #YOUR-PUBLIC-SSH-KEY
  # EOF
}

resource "proxmox_vm_qemu" "master" {
  count = var.master_nodes

  # VM General Settings
  target_node = "proxmox"
  vmid        = "30${count.index + 1}"
  name        = "k3s-m0${count.index + 1}"
  desc        = "Kubernetes Master Node ${count.index + 1}"

  # VM Advanced General Settings
  onboot = true

  # VM OS Settings
  clone = "ubuntu-server-focal"

  # VM System Settings
  agent = 1

  # VM CPU Settings
  cores   = 2
  sockets = 1
  cpu     = "host"

  # VM Memory Settings
  memory = 4096

  # VM Network Settings
  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # VM Cloud-Init Settings
  os_type = "cloud-init"

  # (Optional) IP Address and Gateway
  #ipconfig0 = "ip=192.168.1.125/16,gw=192.168.1.1"
  nameserver = "192.168.1.2"

  # (Optional) Default User
  # ciuser = "your-username"

  # (Optional) Add your SSH KEY
  # sshkeys = <<EOF
  # #YOUR-PUBLIC-SSH-KEY
  # EOF
}
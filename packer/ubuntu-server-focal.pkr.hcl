# Ubuntu Server Focal
# ---
# Packer Template to create an Ubuntu Server (Focal) on Proxmox
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# variables (used from credentials.pkr.hcl)
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true # case sensitive
}

# resource definition for the VM template
source "proxmox-iso" "ubuntu-server-focal" {
 
    # proxmox connection settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true
    
    # VM general settings
    node = "proxmox"
    vm_id = "901"
    vm_name = "ubuntu-server-focal"
    template_description = "Ubuntu Server Focal Cloud Image"

    # VM OS settings
    # (Option 1) local ISO file
    # iso_file = "local:iso/ubuntu-20.04.2-live-server-amd64.iso"
    # - or -
    # (Option 2) download ISO
    iso_url = "https://releases.ubuntu.com/20.04/ubuntu-20.04.6-live-server-amd64.iso"
    iso_checksum = "b8f31413336b9393ad5d8ef0282717b2ab19f007df2e9ed5196c13d8f9153c8b"
    iso_storage_pool = "local"
    unmount_iso = true

    # VM system settings
    qemu_agent = true # qemu-guest-agent is a helper daemon, which is installed in the guest (proxmox). it is used to exchange information between the host and guest, and to execute command in the guest. when enabled, then qemu-guest-agent must be installed on the guest (see user-data).

    # VM hard disk settings
    scsi_controller = "virtio-scsi-pci" # the SCSI controller model to emulate

    # disks attached to the virtual machine
    disks {
        disk_size = "32G"
        format = "raw"
        storage_pool = "local-lvm"
        type = "virtio"
    }

    # VM CPU settings
    cores = "2"
    
    # VM memory settings
    memory = "4096" 

    # VM network settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    } 

    # VM cloud-init settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    # packer boot commands
    boot_command = [
        "<esc><wait><esc><wait>",
        "<f6><wait><esc><wait>",
        "<bs><bs><bs><bs><bs>",
        "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
        "--- <enter>"
    ]
    #boot = "c" # override default boot order -> c: CD-ROM
    boot_wait = "5s"

    # packer autoinstall settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    http_bind_address = "192.168.1.120"
    http_port_min = 8802
    http_port_max = 8802

    ssh_username = "amrap030"

    # (Option 1) Add your Password here
    # ssh_password = "your-password"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    ssh_private_key_file = "~/.ssh/id_rsa"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

# build definition to create the VM template
build {

    name = "ubuntu-server-focal"
    sources = ["source.proxmox-iso.ubuntu-server-focal"]

    # provisioning the VM template for cloud-init integration in proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }

    # provisioning the VM template for cloud-init integration in proxmox #2
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # provisioning the VM template for cloud-Init integration in proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

    # Add additional provisioning scripts here
    # ...
}
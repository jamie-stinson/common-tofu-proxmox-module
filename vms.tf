resource "random_string" "this" {
  for_each = { for key, value in merge(var.talos.node_data.control_plane.nodes, var.talos.node_data.worker.nodes) : key => value }
  length   = 8
  lower    = true
  numeric  = true
  upper    = true
  special  = false
}

resource "random_integer" "this" {
  for_each    = { for key, value in merge(var.talos.node_data.control_plane.nodes, var.talos.node_data.worker.nodes) : key => value }
  min = 1
  max = 50000
}

resource "proxmox_virtual_environment_vm" "this" {
  for_each    = { for key, value in merge(var.talos.node_data.control_plane.nodes, var.talos.node_data.worker.nodes) : key => value }
  name        = format("%s-%s", contains(keys(var.talos.node_data.control_plane.nodes), each.key) ? "controlplane" : "worker", random_string.this[each.key].result)
  node_name   = "projectwhitebox"
  tags        = ["terraform", "talos"]
  vm_id       = random_integer.this[each.key].result

  agent {
    enabled = true
  }

  stop_on_destroy = true
  on_boot         = true

  startup {
    order      = "1"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = "${var.talos.node_data.control_plane.cpu}"
    type  = "host"
  }

  memory {
    dedicated = "${var.talos.node_data.control_plane.memory}"
    floating  = "${var.talos.node_data.control_plane.memory}"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.this.id
    interface    = "virtio0"
  }

  initialization {
    dns {
      servers = [
        var.talos.node_data.primary_dns_server,
        var.talos.node_data.secondary_dns_server
      ]
    }
    ip_config {
      ipv4 {
        address = "${each.key}/24"
        gateway = "${var.talos.node_data.default_gateway}"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
  }
}

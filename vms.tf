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
  for_each = { for key, value in merge(var.talos.node_data.control_plane.nodes, var.talos.node_data.worker.nodes) : 
    key => merge(
      value, 
      {
        type     = contains(keys(var.talos.node_data.control_plane.nodes), key) ? "controlplane" : "worker"
        cpu      = contains(keys(var.talos.node_data.control_plane.nodes), key) ? var.talos.node_data.control_plane.cpu : var.talos.node_data.worker.cpu
        memory   = contains(keys(var.talos.node_data.control_plane.nodes), key) ? var.talos.node_data.control_plane.memory : var.talos.node_data.worker.memory
      }
    )
  }

  name      = format("%s-%s-%s", var.talos.node_data.node_prefix ,each.value.type, random_string.this[each.key].result)
  node_name = "${var.talos.node_data.node_name}"
  tags      = ["terraform", "talos"]
  vm_id     = random_integer.this[each.key].result

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
    cores = tonumber(each.value.cpu)
    type  = "x86-64-v2"
  }

  memory {
    dedicated = tonumber(each.value.memory)
  }


  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.this.id
    interface    = "virtio0"
    size         = "${var.talos.node_data.disk_size}"
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
  depends_on = [
    proxmox_virtual_environment_download_file.this
  ]
}

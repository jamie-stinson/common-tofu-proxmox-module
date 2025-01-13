resource "random_string" "this" {
  for_each = {
    for ip in concat(
      var.talos.cluster.compute.control_plane.nodes,
      var.talos.cluster.compute.worker.nodes
    ) : ip => ip
  }

  length   = 8
  lower    = true
  numeric  = true
  upper    = true
  special  = false
}

resource "random_integer" "this" {
  for_each = {
    for ip in concat(
      var.talos.cluster.compute.control_plane.nodes,
      var.talos.cluster.compute.worker.nodes
    ) : ip => ip
  }

  min = 1
  max = 50000
}

resource "proxmox_virtual_environment_vm" "this" {
  for_each = {
    for ip in concat(
      var.talos.cluster.compute.control_plane.nodes,
      var.talos.cluster.compute.worker.nodes
    ) : ip => {
      type        = contains(var.talos.cluster.compute.control_plane.nodes, ip) ? "controlplane" : "worker"
      subnet_mask = contains(var.talos.cluster.compute.control_plane.nodes, ip) ? var.talos.cluster.compute.control_plane.subnet_mask : var.talos.cluster.compute.worker.subnet_mask
      cpu         = contains(var.talos.cluster.compute.control_plane.nodes, ip) ? var.talos.cluster.compute.control_plane.cpu : var.talos.cluster.compute.worker.cpu
      memory      = contains(var.talos.cluster.compute.control_plane.nodes, ip) ? var.talos.cluster.compute.control_plane.memory : var.talos.cluster.compute.worker.memory
    }
  }

  name      = format("%s%s-%s", var.proxmox.node_prefix, each.value.type, random_string.this[each.key].result)
  node_name = var.proxmox.node_name
  tags      = ["terraform", "talos", "${each.value.type}"]
  vm_id     = random_integer.this[each.key].result

  agent {
    enabled = true
  }

  stop_on_destroy = true
  on_boot         = true

  startup {
    order      = "1"
    up_delay   = "30"
    down_delay = "30"
  }

  cpu {
    cores = tonumber(each.value.cpu)
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = tonumber(each.value.memory)
  }

  operating_system {
      type = "l26"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    file_id      = proxmox_virtual_environment_download_file.this.id
    file_format  = "raw"
    size         = var.talos.cluster.storage.install_disk_size
  }

  initialization {
    dns {
      servers = var.talos.cluster.networking.dns_servers
    }
    ip_config {
      ipv4 {
        address = "${each.key}/${each.value.subnet_mask}"
        gateway = var.talos.cluster.networking.default_gateway
      }
    }
  }

  network_device {
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [disk[0].file_id]
  }

  depends_on = [
    proxmox_virtual_environment_download_file.this
  ]
}

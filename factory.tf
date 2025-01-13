data "http" "schematic_id" {
  url          = "${var.talos.factory.url}/schematics"
  method       = "POST"
  request_body = file("${path.module}/image/schematic.yaml")
}

resource "proxmox_virtual_environment_download_file" "this" {
  node_name    = var.proxmox.node_name
  content_type = "iso"
  datastore_id = "local"
  overwrite    = false
  url          = "${var.talos.factory.url}/image/${jsondecode(data.http.schematic_id.response_body)["id"]}/${var.talos.cluster.talos_version}/${var.talos.factory.platform}-${var.talos.factory.arch}.iso"
  file_name    = "talos-${jsondecode(data.http.schematic_id.response_body)["id"]}-${var.talos.cluster.talos_version}-${var.talos.factory.platform}-${var.talos.factory.arch}.iso"
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    data.http.schematic_id
  ]
}

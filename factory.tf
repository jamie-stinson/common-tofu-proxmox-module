data "http" "schematic_id" {
  url          = "${var.talos.factory.url}/schematics"
  method       = "POST"
  request_body = file("${path.module}/image/schematic.yaml")
}

resource "proxmox_virtual_environment_download_file" "this" {
  node_name               = var.talos.node_data.node_name
  content_type            = "iso"
  datastore_id            = "local"
  decompression_algorithm = "gz"
  overwrite               = false

  url       = "${var.talos.factory.url}/image/${jsondecode(data.http.schematic_id.response_body)["id"]}/${var.talos.cluster.talos_version}/${var.talos.factory.platform}-${var.talos.factory.arch}.raw.gz"
  file_name = "talos-${jsondecode(data.http.schematic_id.response_body)["id"]}-${var.talos.cluster.talos_version}-${var.talos.factory.platform}-${var.talos.factory.arch}.img"
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    data.http.schematic_id
  ]
}

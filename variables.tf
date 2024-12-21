variable "talos" {
  description = "Talos configuration"
  type = object({
    factory = object({
      url      = string
      platform = string
      arch     = string
    })
    cluster = object({
      name               = string
      vip_address        = string
      kubernetes_version = string
      talos_version      = string
    })
    node_data = object({
      default_gateway      = string
      primary_dns_server   = string
      secondary_dns_server = string
      ntp_endpoint         = string
      control_plane = object({
        cpu   = string
        memory = string
        nodes = map(object({}))
      })
      worker = object({
        cpu    = string
        memory = string
        nodes  = map(object({}))
      })
    })
  })
}

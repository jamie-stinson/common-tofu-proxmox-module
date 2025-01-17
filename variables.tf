variable "talos" {
  type = object({
    factory = object({
      url       = string
      platform  = string
      arch      = string
    })
    cluster = object({
      name                = string
      kubernetes_version  = string
      talos_version       = string
      api_server_endpoint = string
      extensions          = optional(list(string))
      networking          = object({
        cni             = string
        pod_subnets     = optional(list(string))
        service_subnets = optional(list(string))
        default_gateway = string
        dns_servers     = list(string)
        ntp_servers     = list(string)
      })
      monitoring          = object({
        kubernetes_metrics_server = optional(bool)
        containerd_metrics_server = optional(bool)
      })
      storage             = object({
        install_disk         = string
        install_disk_size    = string
        encryption_type      = optional(string)
        extra_kubelet_mounts = optional(list(object({
          destination = string
          source     = string
          type       = string
          options    = optional(list(string))
        })))
      })
      compute             = object({
        control_plane = object({
          subnet_mask = string
          nodes       = map(string)
          cpu         = number
          memory      = number
        })
        worker        = object({
          subnet_mask = string
          nodes       = map(string)
          cpu         = number
          memory      = number
        })
      })
    })
  })
}

variable "proxmox" {
  type = object({
    node_prefix = optional(string, "")
    nodes       = list(string)
  })
}

variable "name" {
  type        = string
  description = "The name of the entity you need metadata for."
}

variable "namespace" {
  type        = string
  description = "The namespace of the entity you need metadata for."
  default     = "default"
}

variable "kind" {
  type        = string
  description = "The kind of Backstage entity you are fetch metadata for."
  default     = "Component"
  validation {
    condition     = var.kind == "Component" || var.kind == "Resource" || var.kind == "System" || var.kind == "API"
    error_message = "kind must be one of: 'Component', 'Resource', 'System', 'API'"
  }
}

variable "environment" {
  type        = string
  description = "The name of the environment you are deploying to."
  default     = "unknown"
}

variable "fallback" {
  type = object({
    api_version = string
    kind        = string
    metadata = object({
      annotations = optional(map(string))
      description = optional(string)
      etag        = optional(string)
      labels      = optional(map(string))
      links = optional(list(object({
        icon  = optional(string)
        title = string
        type  = optional(string)
        url   = string
      })))
      name      = string
      namespace = string
      tags      = optional(list(string))
      title     = optional(string)
    })
    relations = optional(list(object({
      target = object({
        kind      = string
        name      = string
        namespace = string
      })
      target_ref = string
      type       = string
    })))
    spec = optional(string)
  })
  description = "The fallback data to use if the Backstage API returns an error or is not reachable. It is recommended to use the terraform_remote_state data source to fetch the data from the remote state backend."
  default     = null
}

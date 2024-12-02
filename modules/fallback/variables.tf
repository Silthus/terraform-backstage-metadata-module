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
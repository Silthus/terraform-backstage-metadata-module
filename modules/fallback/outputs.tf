output "entity" {
  description = "The full component object as defined by the Backstage API."
  value       = var.name
}

output "metadata" {
  description = "A flattened filtered set of metadata from the component object."
  value = {
    entity      = lower(var.name)
    namespace   = lower(var.namespace)
    kind        = lower(var.kind)
    owner       = tostring(null)
    system      = tostring(null)
    lifecycle   = tostring(null)
    type        = tostring(null)
    environment = lower(var.environment)
  }
}

output "labels" {
  description = "A common set of labels to attach to cloud resources."
  value = {
    "created-by"  = "terraform"
    "entity"      = lower(var.name)
    "kind"        = lower(var.kind)
    "owner"       = tostring(null)
    "system"      = tostring(null)
    "lifecycle"   = tostring(null)
    "type"        = tostring(null)
    "environment" = lower(var.environment)
  }
}

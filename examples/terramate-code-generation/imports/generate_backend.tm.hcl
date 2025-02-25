globals "terraform" "backend" "gcs" {
  prefix = "/terramate/stacks/by-id/${terramate.stack.id}"
}

generate_hcl "_terramate_generated_backend.tf" {
  content {
    terraform {
      backend "gcs" {
        bucket = global.terraform.backend.gcs.bucket
        prefix = global.terraform.backend.gcs.prefix
      }
    }
  }
}
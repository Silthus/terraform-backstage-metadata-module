# Configure the GCS backend state bucket
globals "terraform" "backend" "gcs" {
  bucket = "terramate-example-terraform-state-backend"
}

# Configure default Terraform version and default providers
globals "terraform" {
  version = "1.10.5"
}

# Will be added to all stacks
globals "terraform" "providers" "google" {
  source  = "hashicorp/google"
  version = "~> 6.0.0"
  enabled = true
}

globals "terraform" "providers" "google-beta" {
  source  = "hashicorp/google-beta"
  version = "~> 6.0.0"
  enabled = true
}

# Configure the metadata module
globals "metadata_module" {
  # Set to true to globally enable the injection.
  # Use the `inject_metadata` tag on a stack to enable it for a specific stack.
  # enabled               = true
  remote_state_fallback = true

  source  = "github.com/Silthus/terraform-backstage-metadata-module.git"
  version = "v1.0.0"
}

# Backstage provider configuration
globals "terraform" "providers" "backstage" "config" {
  # Configure the base URL of the Backstage instance.
  # base_url = "https://demo.backstage.io"

  # Use one of the following to configure the API key

  # It is recommended to use the secret manager to store the API key.
  # api_key_secret_id = "your-secret-id"
  # api_key_secret_project = "your-project-id"
  # api_key_secret_version = "latest"

  # Use the following to configure the API key directly.
  # Only use this in test environments!
  # api_key = "your-api-key"

  # Use the directly override the Authorization header.
  # headers = {
  #   "Authorization" = "Bearer your-api-key"
  # }

  # Optionally configure the number of retries for the Backstage provider before using the fallback.
  # retries  = 3
}
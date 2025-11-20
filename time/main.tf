terraform {
  required_version = ">= 1.12.0"

  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

resource "time_rotating" "example" {
  rotation_days = 7
}

output "timestamp" {
  value = time_rotating.example.rotation_rfc3339
}

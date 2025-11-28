output "file" {
  description = "The content of the file"
  value = templatefile("${path.module}/kustomization.tftpl", {
    RESOURCES = ["app1", "app2", "app3"]
  })
}

resource "aws_ssm_document" "csr_server_config" {
  name            = "csr-server-config"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/csr-server-config.yaml")

  tags = merge(
    local.tags,
    {
      Name = "csr-server-config"
    },
  )
}
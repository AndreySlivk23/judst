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

resource "aws_ssm_document" "windows_domain_join" {
  name            = "windows-domain-join"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/windows-domain-join.yaml")

  tags = merge(
    local.tags,
    {
      Name = "windows-domain-join"
    },
  )
}

resource "aws_ssm_document" "cloud_watch_agent" {
  name            = "windows-cloudwatch-agent-config"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/windows-cloudwatch-agent-config.yaml")

  tags = merge(
    local.tags,
    {
      Name = "windows-cloudwatch-agent-config"
    },
  )
}
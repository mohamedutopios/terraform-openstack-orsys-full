resource "null_resource" "fake_server" {
  triggers = {
    server_name = "server-001"
    env         = "dev"
  }
}

resource "null_resource" "fake_database" {
  triggers = {
    database_name = "db-prod"
    storage_size  = "5GB"
  }
}

resource "null_resource" "fake_network" {
  triggers = {
    network_name = "network-main"
    cidr_block   = "10.0.0.0/24"
  }
}

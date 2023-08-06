############### Variables ###############

variable "hcloud_token" {
  default = "0QtyGLqWyuWkrPn49Pb5aO7aM80bqqJLusgEAErFpvWDMXcRHQgJEkfgWn3Un77r"
}

# Define provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}



# Define Hetzner provider token
provider "hcloud" {
  token = var.hcloud_token
}

# Obtain ssh key data
data "hcloud_ssh_key" "ssh_key" {
  fingerprint = "c5:e7:80:f0:ed:07:3d:e3:97:19:fa:30:b0:7f:d5:e6"
}

# Create Debian 11 server
resource "hcloud_server" "web" {
  count       = var.instances
  name        = "bot-server-${count.index}"
  image       = var.os_type
  server_type = var.server_type
  location    = var.location
  ssh_keys  = ["${data.hcloud_ssh_key.ssh_key.id}"]
  labels = {
    type = "bot"
  }
  user_data = file("user_data.yml")
}


resource "hcloud_server_network" "web_network" {
  count     = var.instances
  server_id = hcloud_server.web[count.index].id
  subnet_id = hcloud_network_subnet.hc_private_subnet.id
}

resource "hcloud_network_subnet" "hc_private_subnet" {
  network_id   = hcloud_network.hc_private.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.ip_range
}

resource "hcloud_network" "hc_private" {
  name     = "hc_private"
  ip_range = var.ip_range
}

output "web_servers_status" {
  value = {
    for server in hcloud_server.web :
    server.name => server.status
  }
}

output "web_servers_ips" {
  value = {
    for server in hcloud_server.web :
    server.name => server.ipv4_address
  }
}

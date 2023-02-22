terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.1"
    }
  }
}

provider "docker" {
  host = "unix:///run/user/1000/podman/podman.sock"
}

# Start a container
resource "docker_container" "tf_saksa__bastion" {
  name  = "tf_saksa__bastion"
  image = docker_image.tf_bastion_vm.image_id
  networks_advanced {
    name = docker_network.tf_saksa.id
    ipv4_address = "10.89.2.2"
  }
  cgroupns_mode = "host"
  tmpfs = {
    "/tmp": "",
    "/run": "",
    "/run/lock": "",
  }
  volumes {
    host_path = "/sys/fs/cgroup"
    container_path = "/sys/fs/cgroup"
  }
  volumes {
    host_path = "/var/log/journal"
    container_path = "/var/log/journal"
  }
}

resource "docker_container" "tf_saksa__web" {
  name  = "tf_saksa__web"
  image = docker_image.tf_saksa_vm.image_id
  networks_advanced {
    name = docker_network.tf_saksa.id
    ipv4_address = "10.89.2.3"
  }
  cgroupns_mode = "host"
  tmpfs = {
    "/tmp": "",
    "/run": "",
    "/run/lock": "",
  }
  volumes {
    host_path = "/sys/fs/cgroup"
    container_path = "/sys/fs/cgroup"
  }
  volumes {
    host_path = "/var/log/journal"
    container_path = "/var/log/journal"
  }
}

resource "docker_network" "tf_saksa" {
  name = "tf_saksa"
  ipam_options = {
    "driver" = "host-local"
  }
  ipam_config {
    gateway     = "10.89.2.1"
    subnet      = "10.89.2.0/24"
  }
}

# Find the latest Ubuntu precise image.
resource "docker_image" "tf_saksa_vm" {
  name = "tf_saksa_vm"
  keep_locally = true
  build {
    context = "images/saksa"
    tag     = ["tf_saksa_vm:develop"]
  }
}

resource "docker_image" "tf_bastion_vm" {
  name = "tf_bastion_vm"
  keep_locally = true
  build {
    context = "images/bastion"
    tag     = ["tf_bastion_vm:develop"]
  }
}

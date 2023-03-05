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

# Bastion container
resource "docker_container" "tf_saksa__bastion" {
  name  = "tf_saksa__bastion"
  image = docker_image.tf_bastion_vm.image_id
  networks_advanced {
    name = docker_network.tf_saksa.id
    ipv4_address = "10.89.2.2"
  }
  network_mode = "bridge"
  pid_mode = "private"
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

resource "docker_container" "tf_saksa__redpanda" {
  count = 1
  name  = "tf_saksa__redpanda${count.index+1}"
  image = docker_image.tf_redpanda_vm.image_id
  networks_advanced {
    name = docker_network.tf_saksa.id
    ipv4_address = "10.89.2.7${count.index+1}"
  }
  volumes {
    container_path = "/var/lib/redpanda/data"
    volume_name = docker_volume.tf_saksa_redpanda[count.index].name
  }

  provisioner "local-exec" {
    interpreter = [
      "podman", "exec", self.name, "bash", "-c"
    ]
    command = "rpk redpanda mode production; rpk redpanda config bootstrap --self ${self.network_data[0].ip_address} --ips 10.89.2.71; systemctl enable --now redpanda"
  }

  network_mode = "bridge"
  pid_mode = "private"
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

# Scylla containers
resource "docker_container" "tf_saksa__scylla" {
  count = 1
  name  = "tf_saksa__scylla${count.index+1}"
  image = docker_image.tf_scylla_vm.image_id
  networks_advanced {
    name = docker_network.tf_saksa.id
    ipv4_address = "10.89.2.5${count.index+1}"
  }
  volumes {
    container_path = "/var/lib/scylla"
    volume_name = docker_volume.tf_saksa_scylla[count.index].name
  }

  provisioner "local-exec" {
    interpreter = [
      "podman", "exec", self.name, "bash", "-c"
    ]
    command = "scylla_io_setup; systemctl enable --now scylla-server"
  }

  upload {
    file = "/etc/scylla/scylla.yaml"
    content = templatefile("${path.root}/modules/scylla/scylla.yaml.tpl", {
      leader_address = "10.89.2.51",
      listen_address = "10.89.2.5${count.index+1}",
      rpc_address = "10.89.2.5${count.index+1}",
    })
  }

  cgroupns_mode = "host"
  network_mode = "bridge"
  pid_mode = "private"
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

resource "docker_container" "tf_saksa__connect" {
  count = 1
  name  = "tf_saksa__connect${count.index+1}"
  image = docker_image.tf_connect_vm.image_id
  networks_advanced {
    name = docker_network.tf_saksa.id
    ipv4_address = "10.89.2.8${count.index+1}"
  }

  provisioner "local-exec" {
    interpreter = [
      "podman", "exec", self.name, "bash", "-c"
    ]
    command = "systemctl enable --now confluent-kafka-connect"
  }

  upload {
    file = "/etc/kafka/connect-distributed.properties"
    content = templatefile("${path.root}/modules/kafka-connect/connect-distributed.properties.tpl", {
      kafka_bootstrap_servers = "${docker_container.tf_saksa__redpanda[0].network_data[0].ip_address}",
    })
  }

  upload {
    file = "/etc/kafka/scylla-connector.json"
    content = templatefile("${path.root}/modules/kafka-connect/scylla-connector.json.tpl", {
      scylla_cluster_addresses = "${docker_container.tf_saksa__scylla[0].network_data[0].ip_address}",
    })
  }

  cgroupns_mode = "host"
  network_mode = "bridge"
  pid_mode = "private"
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

resource "docker_container" "tf_saksa__nginx" {
  name  = "tf_saksa__nginx"
  image = docker_image.tf_nginx_vm.image_id

  provisioner "local-exec" {
    interpreter = [
      "podman", "exec", self.name, "bash", "-c"
    ]
    command = "ln -s /etc/nginx/sites-available/saksa.conf /etc/nginx/sites-enabled/saksa.conf; systemctl enable --now nginx"
  }

  upload {
    file = "/etc/nginx/sites-available/saksa.conf"
    content = templatefile("${path.root}/modules/nginx/saksa.conf.tpl", {
      server1 = "${docker_container.tf_saksa__web[0].network_data[0].ip_address}",
    })
  }

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.tf_saksa.id
  }
  network_mode = "bridge"
  pid_mode = "private"
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
  volumes {
    container_path = "/var/lib/saksa"
    volume_name = docker_volume.tf_saksa_web.name
  }
}

resource "docker_container" "tf_saksa__web" {
  count = 1
  name  = "tf_saksa__web"
  image = docker_image.tf_saksa_vm.image_id

  provisioner "local-exec" {
    interpreter = [
      "podman", "exec", self.name, "bash", "-c"
    ]
    command = "systemctl enable --now saksa-web"
  }

  upload {
    file = "/etc/systemd/system/saksa-web.service"
    content = file("${path.root}/modules/saksa/saksa-web.service")
  }

  upload {
    file = "/etc/saksa/.env"
    content = templatefile("${path.root}/modules/saksa/config.tpl", {
      KAFKA_BOOTSTRAP_SERVERS = "${docker_container.tf_saksa__redpanda[0].network_data[0].ip_address}",
      SCYLLADB_SERVER = "${docker_container.tf_saksa__scylla[0].network_data[0].ip_address}"
    })
  }

  networks_advanced {
    name = docker_network.tf_saksa.id
    ipv4_address = "10.89.2.3"
  }
  network_mode = "bridge"
  pid_mode = "private"
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
  volumes {
    container_path = "/var/lib/saksa"
    volume_name = docker_volume.tf_saksa_web.name
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

resource "docker_volume" "tf_saksa_web" {
  name = "tf_saksa_web"
}

resource "docker_volume" "tf_saksa_scylla" {
  count = 1
  name = "tf_saksa_scylla${count.index+1}"
}

resource "docker_volume" "tf_saksa_redpanda" {
  count = 1
  name = "tf_saksa_redpanda${count.index+1}"
}

# images
resource "docker_image" "tf_connect_vm" {
  name = "tf_connect_vm"
  keep_locally = true
  build {
    context = "modules/kafka-connect"
    tag     = ["tf_connect_vm:develop"]
  }
}

resource "docker_image" "tf_nginx_vm" {
  name = "tf_nginx_vm"
  keep_locally = true
  build {
    context = "modules/nginx"
    tag     = ["tf_nginx_vm:develop"]
  }
}

resource "docker_image" "tf_saksa_vm" {
  name = "tf_saksa_vm"
  keep_locally = true
  build {
    context = "modules/saksa"
    tag     = ["tf_saksa_vm:develop"]
  }
}

resource "docker_image" "tf_bastion_vm" {
  name = "tf_bastion_vm"
  keep_locally = true
  build {
    context = "modules/bastion"
    tag     = ["tf_bastion_vm:develop"]
  }
}

resource "docker_image" "tf_redpanda_vm" {
  name = "tf_redpanda_vm"
  keep_locally = true
  build {
    context = "modules/redpanda"
    tag     = ["tf_redpanda_vm:develop"]
  }
}

resource "docker_image" "tf_scylla_vm" {
  name = "tf_scylla_vm"
  keep_locally = true
  build {
    context = "modules/scylla"
    tag     = ["tf_scylla_vm:develop"]
  }
}

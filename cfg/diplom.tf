terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
  token = "*******"
  cloud_id = "******"
  folder_id = "*******"
}



resource "yandex_compute_instance" "web-1" {
  name = "nginx1"
  hostname = "nginx1."
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8earpjmhevh8h6ug5o"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    security_group_ids = [yandex_vpc_security_group.web-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/braineater/.ssh/braineater.pub")}"
  }
}

resource "yandex_compute_instance" "web-2" {
  name = "nginx2"
  hostname = "nginx2."
  zone = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8earpjmhevh8h6ug5o"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    security_group_ids = [yandex_vpc_security_group.web-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/braineater/.ssh/braineater.pub")}"
  }
}

resource "yandex_compute_instance" "zabbix" {
  name = "zabbix-server"
  hostname = "zabbix."
  zone = "ru-central1-b"

  resources {
    cores  = 2
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8earpjmhevh8h6ug5o"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    nat = true
    security_group_ids = [yandex_vpc_security_group.zabbix-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/braineater/.ssh/braineater.pub")}"
  }
}

resource "yandex_compute_disk" "elastik-disk" {
  name     = "elastik"
  type     = "network-ssd"
  zone     = "ru-central1-b"
  image_id = "fd8earpjmhevh8h6ug5o"
  size     = 93


}

resource "yandex_compute_instance" "elastik" {
  name = "elastik."
  hostname = "nginx1."
  zone = "ru-central1-b"

  resources {
    cores  = 2
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8earpjmhevh8h6ug5o"
    }
  }
   secondary_disk {
    disk_id = yandex_compute_disk.elastik-disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    security_group_ids = [yandex_vpc_security_group.elastik-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/braineater/.ssh/braineater.pub")}"
  }
}


resource "yandex_compute_instance" "kibana" {
  name = "web-kibana"
  hostname = "kibana."
  zone = "ru-central1-b"

  resources {
    cores  = 2
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8earpjmhevh8h6ug5o"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    nat = true
    security_group_ids = [yandex_vpc_security_group.kibana-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/braineater/.ssh/braineater.pub")}"
  }
}

resource "yandex_compute_instance" "bastion" {
  name = "bastion-host"
  hostname = "bastion."
  zone = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8earpjmhevh8h6ug5o"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    nat = true
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/braineater/.ssh/braineater.pub")}"
  }
}


resource "yandex_vpc_network" "vpc1" {
  name = "network-1"
}

resource "yandex_vpc_subnet" "subnet1" {
  name           = "subnet-1"
  v4_cidr_blocks = ["10.0.129.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc1.id
}

resource "yandex_vpc_subnet" "subnet2" {
  name           = "subnet-2"
  v4_cidr_blocks = ["192.168.1.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc1.id
}

resource "yandex_alb_target_group" "web-target-group" {
  name           = "web-group"

  target {
    subnet_id    = yandex_vpc_subnet.subnet1.id
    ip_address   = yandex_compute_instance.web-1.network_interface.0.ip_address
  }

  target {
    subnet_id    = yandex_vpc_subnet.subnet2.id
    ip_address   = yandex_compute_instance.web-2.network_interface.0.ip_address
  }
}

resource "yandex_alb_backend_group" "web-back" {
  name                     = "web-backend"
  session_affinity {
    connection {
      source_ip = false
    }
  }

  http_backend {
    name                   = "web-backend"
    weight                 = 1
    port                   = 80
    target_group_ids       = [ yandex_alb_target_group.web-target-group.id ]
    load_balancing_config {
      panic_threshold      = 90
    }    
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15 
      http_healthcheck {
        path               = "/"
      }
    }
  }
      depends_on = [yandex_alb_target_group.web-target-group]
}

resource "yandex_alb_http_router" "webrouter" {
  name          = "httprouter"
}

resource "yandex_alb_virtual_host" "diplom" {
  name                    = "diplomnetology"
  http_router_id          = yandex_alb_http_router.webrouter.id
  route {
    name                  = "webdiplom"
    http_route {
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.web-back.id
        timeout           = "60s"
      }
    }
  }
    depends_on = [yandex_alb_backend_group.web-back]
}

resource "yandex_alb_load_balancer" "webbalancer" {
  name        = "my-load-balancer"

  network_id  = yandex_vpc_network.vpc1.id
  
  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet1.id
    }
  }
  
  listener {
    name = "my-web-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.webrouter.id
      }
    }
  }
  
  log_options {
    discard_rule {
      http_code_intervals = ["HTTP_2XX"]
      discard_percent = 75
    }
  }
}

resource "yandex_vpc_security_group" "web-sg" {
  name        = "web security group"
  network_id  = yandex_vpc_network.vpc1.id

ingress {
    description       = "Allow HTTP"
    protocol          = "TCP"
    port              = 80
    v4_cidr_blocks    = ["192.168.1.0/24","10.0.129.0/24"]
  }
ingress {
    description       = "Allow ssh"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }
ingress {
    description       = "Allow zabbix"
    protocol          = "TCP"
    port              = 10050
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
egress {
    description       = "Allow zabbix"
    protocol          = "TCP"
    port              = 10050
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
egress {
    description       = "Allow logstash"
    protocol          = "TCP"
    port              = 5044
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
ingress {
    description       = "Allow logstash"
    protocol          = "TCP"
    port              = 5044
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
  egress {
    description       = "Permit ANY"
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "elastik-sg" {
  name        = "elastik security group"
  network_id  = yandex_vpc_network.vpc1.id

ingress {
    description       = "Allow ssh"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }
ingress {
    description       = "Allow zabbix"
    protocol          = "TCP"
    port              = 10050
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
egress {
    description       = "Allow zabbix"
    protocol          = "TCP"
    port              = 10050
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
egress {
    description       = "Allow logstash"
    protocol          = "TCP"
    port              = 5044
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
ingress {
    description       = "Allow logstash"
    protocol          = "TCP"
    port              = 5044
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
ingress {
    description       = "Allow elastik"
    protocol          = "ANY"
    from_port         = 9200
    to_port           = 9300
    v4_cidr_blocks    = ["127.0.0.1/32"]
  }
egress {
    description       = "Allow elastik"
    protocol          = "ANY"
    from_port         = 9200
    to_port           = 9300
    v4_cidr_blocks    = ["127.0.0.1/32"]
  }


  egress {
    description       = "Permit ANY"
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]

  }
}

resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix security group"
  network_id  = yandex_vpc_network.vpc1.id

ingress {
    description       = "Allow HTTP"
    protocol          = "TCP"
    port              = 80
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }

ingress {
    description       = "Allow ssh"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }
ingress {
    description       = "Allow zabbix"
    protocol          = "TCP"
    port              = 10050
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }
egress {
    description       = "Allow zabbix"
    protocol          = "TCP"
    port              = 10050
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }

ingress {
    description       = "Allow pgsql"
    protocol          = "ANY"
    port              = 5432
    v4_cidr_blocks    = ["127.0.0.1/32"]
  }
egress {
    description       = "Allow pgsql"
    protocol          = "ANY"
    port              = 5432
    v4_cidr_blocks    = ["127.0.0.1/32"]
  }


  egress {
    description       = "Permit ANY"
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]

  }
}

resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana security group"
  network_id  = yandex_vpc_network.vpc1.id

ingress {
    description       = "Allow ssh"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }
ingress {
    description       = "Allow zabbix"
    protocol          = "TCP"
    port              = 10050
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
egress {
    description       = "Allow zabbix"
    protocol          = "TCP"
    port              = 10050
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }

ingress {
    description       = "Allow elastik"
    protocol          = "ANY"
    from_port         = 9200
    to_port           = 9300
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
egress {
    description       = "Allow elastik"
    protocol          = "ANY"
    from_port         = 9200
    to_port           = 9300
    v4_cidr_blocks    = ["192.168.1.0/24"]
  }
ingress {
    description       = "Allow kibana"
    protocol          = "ANY"
    port              = 5601
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }
egress {
    description       = "Allow kibana"
    protocol          = "ANY"
    port              = 5601
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }


  egress {
    description       = "Permit ANY"
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]

  }
}


resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion security group"
  network_id  = yandex_vpc_network.vpc1.id

ingress {
    description       = "Allow ssh"
    protocol          = "TCP"
    port              = 22
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }
egress {
    description       = "Allow ssh"
    protocol          = "TCP"
    port              = 22
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }
  egress {
    description       = "Permit ANY"
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]

  }
}



output "internal_ip_address_web_1" {
  value = yandex_compute_instance.web-1.network_interface.0.ip_address
}

output "internal_ip_address_web_2" {
  value = yandex_compute_instance.web-2.network_interface.0.ip_address
}
output "internal_ip_address_zabbix" {
  value = yandex_compute_instance.zabbix.network_interface.0.ip_address
}
output "external_ip_address_zabbix" {
  value = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

output "internal_ip_address_elastik" {
  value = yandex_compute_instance.elastik.network_interface.0.ip_address
}
output "external_ip_address_kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}
output "internal_ip_address_kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}
output "external_ip_address_bastion" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}
output "internal_ip_address_bastion" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

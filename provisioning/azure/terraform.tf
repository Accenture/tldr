# Configure the Azure Provider
provider "azure" {
  settings_file = "${file("credentials.publishsettings")}"
}
resource "azure_storage_service" "tldr" {
    name = "tldr"
    location = "North Europe"
    description = "Made by Terraform."
    account_type = "Standard_LRS"
}
resource "azure_hosted_service" "terraform-infra" {
     name = "tldr-infra"
     location = "North Europe"
     ephemeral_contents = false
     description = "Hosted service created by Terraform."
     label = "tf-hs-01"
}
resource "azure_hosted_service" "terraform-registry" {
     name = "tldr-registry"
     location = "North Europe"
     ephemeral_contents = false
     description = "Hosted service created by Terraform."
     label = "tf-hs-01"
}
resource "azure_hosted_service" "terraform-swarm-azure-0" {
     name = "tldr-swarm-azure-0"
     location = "North Europe"
     ephemeral_contents = false
     description = "Hosted service created by Terraform."
     label = "tf-hs-01"
}
resource "azure_hosted_service" "terraform-swarm-azure-1" {
     name = "tldr-swarm-azure-1"
     location = "North Europe"
     ephemeral_contents = false
     description = "Hosted service created by Terraform."
     label = "tf-hs-01"
}
resource "azure_hosted_service" "terraform-swarm-azure-2" {
     name = "tldr-swarm-azure-2"
     location = "North Europe"
     ephemeral_contents = false
     description = "Hosted service created by Terraform."
     label = "tf-hs-01"
}
resource "azure_virtual_network" "tldr-vnet" {
    name = "tldr-vnet"
    address_space = ["10.0.0.0/16"]
    location = "North Europe"
    subnet {
        name = "tldr-subnet-1"
        address_prefix = "10.0.1.0/24"
    }
}
resource "azure_security_group" "tldr-registry" {
    name = "tldr-registry"
    location = "North Europe"
}
resource "azure_security_group" "tldr-node" {
    name = "tldr-node"
    location = "North Europe"
}
resource "azure_security_group" "tldr-infra-node" {
    name = "tldr-infra-node"
    location = "North Europe"
}
resource "azure_security_group_rule" "ssh_access" {
    name = "ssh-access-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 100
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "22"
    protocol = "TCP"
}
resource "azure_security_group_rule" "docker_access" {
    name = "docker-access-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 200
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "2376"
    protocol = "TCP"
}
resource "azure_security_group_rule" "swarm-master" {
    name = "swarmaster-access-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 300
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "3376"
    protocol = "TCP"
}
resource "azure_security_group_rule" "consul" {
    name = "consul-access-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 400
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "7946"
    protocol = "TCP"
}
resource "azure_security_group_rule" "consul2" {
    name = "consul2-access-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 500
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "8500"
    protocol = "TCP"
}
resource "azure_security_group_rule" "load-balancer" {
    name = "load-balancer-haproxy-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 600
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "80"
    protocol = "TCP"
}
resource "azure_security_group_rule" "load-balancer2" {
    name = "load-balancer-admin-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 700
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "1936"
    protocol = "TCP"
}
resource "azure_security_group_rule" "cdavisor" {
    name = "cadvisor-admin-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 800
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "8080"
    protocol = "TCP"
}
resource "azure_security_group_rule" "outbound" {
    name = "outbound-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Outbound"
    action = "Allow"
    priority = 900
    source_address_prefix = "10.0.0.0/16"
    source_port_range = "*"
    destination_address_prefix = "0.0.0.0/0"
    destination_port_range = "*"
    protocol = "*"
}
resource "azure_security_group_rule" "kibana" {
    name = "kibana-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 910
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "5601"
    protocol = "TCP"
}
resource "azure_security_group_rule" "temp" {
    name = "temp-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 915
    source_address_prefix = "10.0.0.0/16"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "*"
    protocol = "TCP"
}
resource "azure_security_group_rule" "syslog" {
    name = "syslog-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 920
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "5000"
    protocol = "UDP"
}
resource "azure_security_group_rule" "prometheus" {
    name = "prometheus-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 930
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "9090"
    protocol = "TCP"
}
resource "azure_security_group_rule" "promdash" {
    name = "promdash-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 940
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "8080"
    protocol = "TCP"
}
resource "azure_security_group_rule" "registry" {
    name = "registry-admin-rule"
    security_group_names = ["${azure_security_group.tldr-registry.name}", "${azure_security_group.tldr-node.name}", "${azure_security_group.tldr-infra-node.name}"]
    type = "Inbound"
    action = "Allow"
    priority = 950
    source_address_prefix = "0.0.0.0/0"
    source_port_range = "*"
    destination_address_prefix = "10.0.0.0/16"
    destination_port_range = "5000"
    protocol = "TCP"
}
resource "azure_instance" "tldr-registry" {
    name = "tldr-registry-azure"
    hosted_service_name = "${azure_hosted_service.terraform-registry.name}"
    image = "Ubuntu Server 14.04 LTS"
    size = "Basic_A1"
    storage_service_name = "tldr"
    location = "North Europe"
    virtual_network = "${azure_virtual_network.tldr-vnet.name}"
    subnet = "tldr-subnet-1"
    security_group = "${azure_security_group.tldr-registry.name}"
    username = "azureuser"
    password = "Accenture123!"
    provisioner "remote-exec" {
        script ="/home/ec2-user/tldr/provisioning/azure/installdocker.sh"
    }
    provisioner file {
        source = "/root/.ssh/id_rsa.pub"
        destination = "/home/azureuser/.ssh/authorized_keys"
    } 
    provisioner "local-exec" {
        command = "docker-machine create -d generic --generic-ip-address=${azure_instance.tldr-registry.vip_address} --generic-ssh-user=azureuser --engine-insecure-registry=${azure_instance.tldr-registry.vip_address}:5000 tldr-registry-azure"
    }
    endpoint {    
        name = "ssh"
        protocol = "tcp"
        public_port = 22
        private_port = 22
    }
    endpoint {
        name = "docker"
        protocol = "tcp"
        public_port = 2376
        private_port = 2376
    }
    endpoint {
        name = "tcp5000"
        protocol = "tcp"
        public_port = 5000
        private_port = 5000
    }
    endpoint {
        name = "tcp443"
        protocol = "tcp"
        public_port = 443
        private_port = 443
    }
}
resource "azure_instance" "tldr-infra" {
    name = "tldr-infra-azure"
    depends_on = ["azure_instance.tldr-registry"]
    hosted_service_name = "${azure_hosted_service.terraform-infra.name}"
    image = "Ubuntu Server 14.04 LTS"
    size = "Basic_A1"
    storage_service_name = "tldr"
    location = "North Europe"
    virtual_network = "${azure_virtual_network.tldr-vnet.name}"
    subnet = "tldr-subnet-1"     
    security_group = "${azure_security_group.tldr-infra-node.name}"
    username = "azureuser"
    password = "Accenture123!"
    provisioner "remote-exec" {
        script ="/home/ec2-user/tldr/provisioning/azure/installdocker.sh"
    }
    provisioner file {
        source = "/root/.ssh/id_rsa.pub"
        destination = "/home/azureuser/.ssh/authorized_keys"
   }
   provisioner "local-exec" {
        command = "docker-machine create -d generic --generic-ip-address=${azure_instance.tldr-infra.vip_address} --generic-ssh-user=azureuser --engine-insecure-registry=${azure_instance.tldr-registry.vip_address}:5000 tldr-infra-azure"
   }
   endpoint {
       name = "SSH"
       protocol = "tcp"
       public_port = 22
       private_port = 22
    }
   endpoint {
        name = "docker"
        protocol = "tcp"
        public_port = 2376
        private_port = 2376
    }
    endpoint {
        name = "Kibana"
        protocol = "tcp"
        public_port = 5601
        private_port = 5601
    }
    endpoint {
        name = "consul"
        protocol = "tcp"
        public_port = 8500
        private_port = 8500
    }
    endpoint {
        name = "prometheus"
        protocol = "tcp"
        public_port = 9090
        private_port = 9090
    }
    endpoint {
        name = "promdash"
        protocol = "tcp"
        public_port = 3000
        private_port = 3000
    }
    endpoint {
        name = "syslog"
        protocol = "udp"
        public_port = 5000
        private_port = 5000
    }
}
resource "azure_instance" "tldr-swarm-azure-0" {
    name = "tldr-swarm-azure-0"
    depends_on = ["azure_instance.tldr-registry"]
    hosted_service_name = "${azure_hosted_service.terraform-swarm-azure-0.name}"
    image = "Ubuntu Server 14.04 LTS"
    size = "Basic_A1"
    storage_service_name = "tldr"
    location = "North Europe"
    virtual_network = "${azure_virtual_network.tldr-vnet.name}"
    subnet = "tldr-subnet-1"
    security_group = "${azure_security_group.tldr-node.name}"
    username = "azureuser"
    password = "Accenture123!"   
    provisioner "remote-exec" {
        script ="/home/ec2-user/tldr/provisioning/azure/installdocker.sh"
   }
   provisioner file {
        source = "/root/.ssh/id_rsa.pub"
        destination = "/home/azureuser/.ssh/authorized_keys"
   }
   provisioner "local-exec" {
        command = "docker-machine create -d generic --generic-ip-address=${azure_instance.tldr-swarm-azure-0.vip_address} --generic-ssh-user=azureuser --swarm --swarm-master --swarm-discovery=consul://${azure_instance.tldr-infra.vip_address}:8500 --swarm-image swarm --engine-opt=cluster-store=consul://${azure_instance.tldr-infra.vip_address}:8500 --engine-insecure-registry=${azure_instance.tldr-registry.vip_address}:5000 --engine-opt=cluster-advertise=eth0:2376 tldr-swarm-azure-0"
   }
    endpoint {
        name = "SSH"
        protocol = "tcp"
        public_port = 22
        private_port = 22
    }
    endpoint {
        name = "docker"
        protocol = "tcp"
        public_port = 2376
        private_port = 2376
    }
    endpoint {
        name = "Kibana"
        protocol = "tcp"
        public_port = 5601
        private_port = 5601
    }
    endpoint {
        name = "KibanaUDP"
        protocol = "udp"
        public_port = 5000
        private_port = 5000
    }
    endpoint {
        name = "consul"
        protocol = "tcp"
        public_port = 8500
        private_port = 8500
    }    
    endpoint {
        name = "swarm"
        protocol = "tcp"
        public_port = 3376
        private_port = 3376
    }
    endpoint {
        name = "consul2"
        protocol = "tcp"
        public_port = 7946
        private_port = 7946
    }
    endpoint {
        name = "LB"
        protocol = "tcp"
        public_port = 80
        private_port = 80
    }
    endpoint {
        name = "LBadmin"
        protocol = "tcp"
        public_port = 1936
        private_port = 1936
    }
    endpoint {
        name = "advisor"
        protocol = "tcp"
        public_port = 8080
        private_port = 8080
    }
}
resource "azure_instance" "tldr-swarm-azure-1" {
    name = "tldr-swarm-azure-1"
    depends_on = ["azure_instance.tldr-swarm-azure-0"]
    hosted_service_name = "${azure_hosted_service.terraform-swarm-azure-1.name}"
    image = "Ubuntu Server 14.04 LTS"
    size = "Basic_A1"
    storage_service_name = "tldr"
    location = "North Europe"
    virtual_network = "${azure_virtual_network.tldr-vnet.name}"
    subnet = "tldr-subnet-1"
    security_group = "${azure_security_group.tldr-node.name}"
    username = "azureuser"
    password = "Accenture123!"
    provisioner "remote-exec" {
        script ="/home/ec2-user/tldr/provisioning/azure/installdocker.sh"
   }
   provisioner file {
        source = "/root/.ssh/id_rsa.pub"
        destination = "/home/azureuser/.ssh/authorized_keys"
   }
   provisioner "local-exec" {
        command = "docker-machine create -d generic --generic-ip-address=${azure_instance.tldr-swarm-azure-1.vip_address} --generic-ssh-user=azureuser --swarm --swarm-discovery=consul://${azure_instance.tldr-infra.vip_address}:8500 --swarm-image swarm --engine-opt=cluster-store=consul://${azure_instance.tldr-infra.vip_address}:8500 --engine-insecure-registry=${azure_instance.tldr-registry.vip_address}:5000 --engine-opt=cluster-advertise=eth0:2376 --engine-opt=log-driver=syslog --engine-label=type=frontend tldr-swarm-azure-1"   
   }
 endpoint {
        name = "SSH"
        protocol = "tcp"
        public_port = 22
        private_port = 22
    }
    endpoint {
        name = "docker"
        protocol = "tcp"
        public_port = 2376
        private_port = 2376
    }
    endpoint {
        name = "Kibana"
        protocol = "tcp"
        public_port = 5601
        private_port = 5601
    }
    endpoint {
        name = "KibanaUDP"
        protocol = "udp"
        public_port = 5000
        private_port = 5000
    }
    endpoint {
        name = "consul"
        protocol = "tcp"
        public_port = 8500
        private_port = 8500
    }
    endpoint {
        name = "swarm"
        protocol = "tcp"
        public_port = 3376
        private_port = 3376
    }
    endpoint {
        name = "consul2"
        protocol = "tcp"
        public_port = 7946
        private_port = 7946
    }
    endpoint {
        name = "LB"
        protocol = "tcp"
        public_port = 80
        private_port = 80
    }
    endpoint {
        name = "LBadmin"
        protocol = "tcp"
        public_port = 1936
        private_port = 1936
    }
    endpoint {
        name = "advisor"
        protocol = "tcp"
        public_port = 8080
        private_port = 8080
    }
}
resource "azure_instance" "tldr-swarm-azure-2" {
    name = "tldr-swarm-azure-2"
    depends_on = ["azure_instance.tldr-swarm-azure-0"]
    hosted_service_name = "${azure_hosted_service.terraform-swarm-azure-2.name}"
    image = "Ubuntu Server 14.04 LTS"
    size = "Basic_A1"
    storage_service_name = "tldr"
    location = "North Europe"
    virtual_network = "${azure_virtual_network.tldr-vnet.name}"
    subnet = "tldr-subnet-1"
    security_group = "${azure_security_group.tldr-node.name}"
    username = "azureuser"
    password = "Accenture123!"
    provisioner "remote-exec" {
        script ="/home/ec2-user/tldr/provisioning/azure/installdocker.sh"
   }
   provisioner file {
        source = "/root/.ssh/id_rsa.pub"
        destination = "/home/azureuser/.ssh/authorized_keys"
   }
   provisioner "local-exec" {
        command = "docker-machine create -d generic --generic-ip-address=${azure_instance.tldr-swarm-azure-2.vip_address} --generic-ssh-user=azureuser --swarm --swarm-discovery=consul://${azure_instance.tldr-infra.vip_address}:8500 --swarm-image swarm --engine-opt=cluster-store=consul://${azure_instance.tldr-infra.vip_address}:8500 --engine-insecure-registry=${azure_instance.tldr-registry.vip_address}:5000 --engine-opt=cluster-advertise=eth0:2376 --engine-opt=log-driver=syslog --engine-label=type=application tldr-swarm-azure-2"
   }
 endpoint {
        name = "SSH"
        protocol = "tcp"
        public_port = 22
        private_port = 22
    }
    endpoint {
        name = "docker"
        protocol = "tcp"
        public_port = 2376
        private_port = 2376
    }
    endpoint {
        name = "Kibana"
        protocol = "tcp"
        public_port = 5601
        private_port = 5601
    }
    endpoint {
        name = "KibanaUDP"
        protocol = "udp"
        public_port = 5000
        private_port = 5000
    }
    endpoint {
        name = "consul"
        protocol = "tcp"
        public_port = 8500
        private_port = 8500
    }
    endpoint {
        name = "swarm"
        protocol = "tcp"
        public_port = 3376
        private_port = 3376
    }
    endpoint {
        name = "consul2"
        protocol = "tcp"
        public_port = 7946
        private_port = 7946
    }
    endpoint {
        name = "LB"
        protocol = "tcp"
        public_port = 80
        private_port = 80
    }
    endpoint {
        name = "LBadmin"
        protocol = "tcp"
        public_port = 1936
        private_port = 1936
    }
    endpoint {
        name = "advisor"
        protocol = "tcp"
        public_port = 8080
        private_port = 8080
    }
}
output "tldr-registry-azure" {
    value = "${azure_instance.tldr-registry.vip_address}"
}
output "tldr-infra-azure" {
    value = "${azure_instance.tldr-infra.vip_address}"
}
output "tldr-swarm-azure-0" {
    value = "${azure_instance.tldr-swarm-azure-0.vip_address}"
}
output "tldr-swarm-azure-1" {
    value = "${azure_instance.tldr-swarm-azure-1.vip_address}"
}
output "tldr-swarm-azure-2" {
    value = "${azure_instance.tldr-swarm-azure-2.vip_address}"
}





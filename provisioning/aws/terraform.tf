provider "aws" {
    # access key, secret and region will be retrieved from environment variables
}

resource "aws_vpc" "tldr-vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true" 

    tags {
        Name = "tldr-vpc"
    }
}

resource "aws_internet_gateway" "tldr-igw" {
    vpc_id = "${aws_vpc.tldr-vpc.id}"

    tags {
        Name = "tldr-igw"
    }
}

resource "aws_subnet" "tldr-subnet-1" {
    vpc_id = "${aws_vpc.tldr-vpc.id}"
    cidr_block = "10.0.1.0/24"
    
    # This seems to be optional, we leave out for now
    #availability_zone = "${var.availability_zone}"
    
    map_public_ip_on_launch = "false"

    tags {
        Name = "tldr-subnet-1"
    }
}


resource "aws_route_table" "tldr-route-table" {
    vpc_id = "${aws_vpc.tldr-vpc.id}"
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.tldr-igw.id}"
    }

    tags {
        Name = "tldr-route-table"
    }
}

# No inbound traffic from the internet will reach our instance without this
resource "aws_main_route_table_association" "tldr-main_route_table_association" {
    vpc_id = "${aws_vpc.tldr-vpc.id}"
    route_table_id = "${aws_route_table.tldr-route-table.id}"
}

# Security group for Docker Machine nodes
resource "aws_security_group" "tldr-node" {
  name = "tldr-node"
  description = "Security group for TLDR nodes"
  vpc_id = "${aws_vpc.tldr-vpc.id}"

  # ssh
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

 # docker daemon
 ingress {
      from_port = 2376
      to_port = 2376
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

 # Swarm master
 ingress {
      from_port = 3376
      to_port = 3376
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }  

 # Consul
 ingress {
      from_port = 8500
      to_port = 8500
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }  

  # consul
  ingress {
    from_port = 7946
    to_port = 7946
    protocol = "tcp"
    #security_groups = ["tldr-node"]
    self = true
  }

  # allow all traffic within the security group
  ingress {
    from_port = 0
    to_port = 0
    self = true
    protocol = "-1"
  }

  # load balancer/haproxy
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

 # load balancer/haproxy - admin interface
 ingress {
      from_port = 1936
      to_port = 1936
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  # cAdvisor
  ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  
  }

  # icmp
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    self = true
  }

  # allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "tldr-node"
  }
}

# Security group for the infra node
resource "aws_security_group" "tldr-infra-node" {
  name = "tldr-infra-node"
  description = "Security group for TLDR infra node"
  vpc_id = "${aws_vpc.tldr-vpc.id}"

 # allow all traffic within the security group
  ingress {
    from_port = 0
    to_port = 0
    self = true
    protocol = "-1"
  }  

  # ssh
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

 # docker daemon
 ingress {
      from_port = 2376
      to_port = 2376
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

 # Consul
 ingress {
      from_port = 8500
      to_port = 8500
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  # Kibana
  ingress {
    from_port = 5601
    to_port = 5601
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Syslog (logstash)
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "udp"
    security_groups = [ "${aws_security_group.tldr-node.id}" ]
  }

  # Prometheus
  ingress {
    from_port = 9090
    to_port = 9090
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  # PromDash 
  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  # allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "tldr-infra-node"
  }
}

resource "aws_security_group" "tldr-registry" {
  name = "tldr-registry"
  description = "Security group for TLDR nodes"
  vpc_id = "${aws_vpc.tldr-vpc.id}"

 # allow all traffic within the security group
  ingress {
    from_port = 0
    to_port = 0
    self = true
    protocol = "-1"
  }  

  # ssh
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  # docker daemon
  ingress {
      from_port = 2376
      to_port = 2376
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  } 

  # registry port
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "tldr-registry"
  }
}
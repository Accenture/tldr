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
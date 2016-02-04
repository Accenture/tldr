# TLDR AWS Provisioning

This folder provisions a basic configuration on AWS to run TLDR, with a VPC containing a subnet and an internet gateway to access it.

# Pre-requisites

- Terraform 0.6 or newer: https://terraform.io.

# Credentials

Before starting, provision an the needed credentials from the AWS admin console, and export them as environment variables:

```
export AWS_ACCESS_KEY_ID=<access-key-id>
export AWS_SECRET_ACCESS_KEY=<secret-access-key>
epxort AWS_DEFAULT_REGION=<default-region, e.g. eu-west>
```

# Provisioning the infrastructure

Run ```terraform apply``` or use the ```provision.sh``` script (it will check that all the needed variables are in place for you).

The provisioning process will take a few minutes, and Terraform will report errors if any during the process.

When done, use ```terraform show``` to see the results and note the values of ```vpc_id``` and ```availability_zone```, as they will be needed in the next step.

# Testing

Provision a test node via Docker Machine:

```
docker-machine create --driver amazonec2 --amazonec2-access-key $AWS_ACCESS_KEY_ID --amazonec2-secret-key $AWS_SECRET_ACCESS_KEY --amazonec2-vpc-id <AWS_VPC_ID> --amazonec2-zone <ZONE> aws-test
```

Replace the values for AWS_VPC_ID and ZONE accordingly. The former depends on the output of the ```terraform show``` command as described above.
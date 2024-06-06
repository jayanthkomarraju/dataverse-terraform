provider "aws" {
  region = "us-east-1"  # Specify your AWS region
}

# Define your VPC ID
variable "vpc_id" {
  description = "Your VPC ID"
  type        = string
}

# Define your Subnet ID
variable "subnet_id" {
  description = "Your Subnet ID"
  type        = string
}

# Use existing security group
variable "security_group_id" {
  description = "Your Security Group ID"
  type        = string
}

# Create a key pair
resource "aws_key_pair" "dataverse_key" {
  key_name   = "dataverse-key"
  public_key = tls_private_key.dataverse_key.public_key_openssh
}

# Generate a TLS private key
resource "tls_private_key" "dataverse_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_instance" "dataverse" {
  ami                         = "ami-0408f4c4a072e3fb9"  # Rocky Linux 8.9 AMI ID
  instance_type               = "t3a.large"
  key_name                    = aws_key_pair.dataverse_key.key_name
  vpc_security_group_ids      = [var.security_group_id]  # Specify your security group ID
  subnet_id                   = var.subnet_id            # Specify your subnet ID
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash -e

              # Install epel-release and other necessary packages
              sudo dnf -q -y install epel-release
              sudo dnf -q -y install ansible git

              # Clone the dataverse-ansible repository
              git clone -b develop https://github.com/GlobalDataverseCommunityConsortium/dataverse-ansible.git /home/rocky/dataverse

              # Run the Ansible playbook to set up Dataverse
              cd /home/rocky/dataverse
              ansible-playbook -i inventory dataverse.pb --connection=local
              EOF

  tags = {
    Name = "DataverseInstance"
  }
}

output "instance_public_ip" {
  value = aws_instance.dataverse.public_ip
}

output "instance_public_dns" {
  value = aws_instance.dataverse.public_dns
}

output "private_key_pem" {
  value     = tls_private_key.dataverse_key.private_key_pem
  sensitive = true
}

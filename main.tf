provider "aws" {
  region = "us-east-1"  # Specify your AWS region
}

resource "aws_security_group" "dataverse_sg" {
  name        = "dataverse-sg"
  description = "Security group for Dataverse"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dataverse" {
  ami                         = "ami-0408f4c4a072e3fb9"  # Rocky Linux 8.9 AMI ID
  instance_type               = "t3a.large"
  key_name                    = "your-key-name"  # Replace with your key pair name
  security_groups             = [aws_security_group.dataverse_sg.name]
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

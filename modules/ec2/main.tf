# modules/ec2/main.tf

# =================================================================
# Dynamic AMI Data Source
# =================================================================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-20*-x86_64"]
  }

  filter {
    name   = "name"
    values = ["*-kernel-6.*"] 
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# =================================================================
# IAM Role 
# =================================================================
# for Bastion (SSM, ECR Access)
resource "aws_iam_role" "bastion_ssm_role" {
  name = "standard-bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# =================================================================
# Policy Attachments
# =================================================================
# ECR Access Permissions
resource "aws_iam_role_policy_attachment" "bastion_ecr_attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# SSM Core Permissions
resource "aws_iam_role_policy_attachment" "bastion_ssm_attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# =================================================================
# Instance Profile for EC2
# =================================================================
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "standard-bastion-instance-profile"
  role = aws_iam_role.bastion_ssm_role.name
}

# =================================================================
# EC2 Instance
# =================================================================
# Bastion
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_1a_id
  vpc_security_group_ids = [var.bastion_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  user_data = <<-EOF
            #!/bin/bash
            dnf update -y
            dnf install -y docker git
            systemctl start docker
            systemctl enable docker
            usermod -aG docker ec2-user
            EOF

  tags = {
    Name = "standard-bastion-ec2"
  }
}

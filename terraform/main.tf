# Deliberately misconfigured Terraform for security scanning demo

# MISCONFIGURATION 1: S3 bucket with public read access
resource "aws_s3_bucket" "vulnerable_bucket" {
  bucket = "my-vulnerable-bucket-${random_string.bucket_suffix.result}"
}

resource "aws_s3_bucket_public_access_block" "vulnerable_bucket_pab" {
  bucket = aws_s3_bucket.vulnerable_bucket.id

  # SECURITY ISSUE: Allowing public access
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "vulnerable_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.vulnerable_bucket_acl_ownership]

  bucket = aws_s3_bucket.vulnerable_bucket.id
  # SECURITY ISSUE: Public read access
  acl = "public-read"
}

resource "aws_s3_bucket_ownership_controls" "vulnerable_bucket_acl_ownership" {
  bucket = aws_s3_bucket.vulnerable_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# MISCONFIGURATION 2: Security group with unrestricted access
resource "aws_security_group" "vulnerable_sg" {
  name_prefix = "vulnerable-sg-"
  description = "Vulnerable security group for demo"
  vpc_id      = aws_vpc.main.id

  # SECURITY ISSUE: Allow all inbound traffic from anywhere
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # VULNERABLE: Allow from anywhere
  }

  # SECURITY ISSUE: SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # VULNERABLE: SSH from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vulnerable-security-group"
  }
}

# MISCONFIGURATION 3: EC2 instance with IMDSv1 enabled
resource "aws_instance" "vulnerable_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.vulnerable_sg.id]
  subnet_id              = aws_subnet.public.id

  # SECURITY ISSUE: IMDSv1 enabled (should be disabled)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional" # Should be "required" for IMDSv2 only
  }

  # SECURITY ISSUE: No encryption for EBS volumes
  root_block_device {
    volume_size = 10
    encrypted   = false # Should be true
  }

  tags = {
    Name = "vulnerable-instance"
  }
}

# Supporting resources
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vulnerable-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
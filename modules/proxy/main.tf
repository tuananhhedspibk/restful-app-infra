locals {
  ami = "ami-079a2a9ac6ed876fc"
}

resource "aws_security_group" "proxy" {
  name        = "${var.app_name}-${var.env_name}-proxy-sg"
  description = "Allow ssh connect to db proxy"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.env_name}-proxy-sg"
  }
}

resource "aws_instance" "proxy" {
  instance_type = "t2.micro"

  ami = local.ami

  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.proxy.id]
  key_name        = "newanigram"

  tags = {
    Name = "${var.app_name}-${var.env_name}-db-proxy"
  }
}

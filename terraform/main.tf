provider "aws" {
  region = var.region
}

// vpc + subnet

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = "rke2-vpc" })
}

resource "aws_subnet" "this" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false
  tags = merge(var.tags, { Name = "rke2-subnet" })
}


// IGW + RT

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}


// SG - bastian host

resource "aws_security_group" "bastion" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.this.id

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
}


// SG - control plane

resource "aws_security_group" "bastion" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.this.id

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
}


// SG - worker / data plane


resource "aws_security_group" "worker" {
  name   = "rke2-worker-sg"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "worker_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.worker.id
}

resource "aws_security_group_rule" "worker_kubelet" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  cidr_blocks       = [var.subnet_cidr]
  security_group_id = aws_security_group.worker.id
}

resource "aws_security_group_rule" "nodeport" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = [var.subnet_cidr]
  security_group_id = aws_security_group.worker.id
}


// EC2 - bastian host


resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.this.id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]

  tags = merge(var.tags, { Name = "bastion" })
}


// EC2 -  3 * CONTROL PLANE

resource "aws_instance" "cp" {
  count                    = 3
  ami                      = var.ami_id
  instance_type            = var.instance_type
  subnet_id                = aws_subnet.this.id
  key_name                 = var.key_name
  vpc_security_group_ids   = [aws_security_group.cp.id]

  tags = merge(var.tags, {
    Name = "cp-${count.index + 1}"
  })
}


// EC2 - 2 * WORKER


resource "aws_instance" "worker" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.this.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.worker.id]

  tags = merge(var.tags, {
    Name = "worker-${count.index + 1}"
  })
}

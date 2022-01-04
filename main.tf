provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}
data "aws_availability_zones" "az" {
  state = "available"
}
/*data "aws_route_table" "rt" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }
}*/
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "Main"
  }
}
resource "aws_subnet" "public" {
  count                   = var.pub_sub_count
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(data.aws_availability_zones.az.names, count.index)
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet_${count.index}"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}
resource "aws_subnet" "private" {
  count                   = var.priv_sub_count
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(data.aws_availability_zones.az.names, count.index)
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  map_public_ip_on_launch = true
  tags = {
    Name = "private-subnet_${count.index}"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "prakash"
  }
}
resource "aws_nat_gateway" "nat" {
  count         = var.nat_count
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[count.index].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Public-route"
  }
}
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
/*
resource "aws_route_table_association" "rta" {
  count          = var.pub_sub_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.rt.id
}*/
resource "aws_route_table_association" "public" {
  count          = var.pub_sub_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Private-route"
  }
}
resource "aws_route" "private" {
  count                  = var.nat_count
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat[count.index].id
}
resource "aws_route_table_association" "private" {
  count          = var.pub_sub_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
data "aws_security_group" "sg" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }
}
resource "aws_instance" "public" {
  count                       = var.pub_instance_count
  subnet_id                   = aws_subnet.public[count.index].id
  ami                         = "ami-0851b76e8b1bce90b"
  instance_type               = var.pub_instance_type
  key_name                    = "prakash_key"
  associate_public_ip_address = true
  security_groups             = [data.aws_security_group.sg.id]
  tags = {
    Name = var.pub_instancename
  }
}
resource "aws_instance" "private" {
  count                       = var.priv_instance_count
  subnet_id                   = aws_subnet.private[count.index].id
  ami                         = "ami-0851b76e8b1bce90b"
  instance_type               = var.priv_instance_type
  key_name                    = "prakash_key"
  associate_public_ip_address = false
  security_groups             = [data.aws_security_group.sg.id]
  tags = {
    Name = var.priv_instancename
  }
}

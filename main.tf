provider "aws" {
  region  = "ap-south-1"
  profile = "alphav"
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
  count = var.nat_count ? 1 : 0
  # subnet = aws_subnet.private ? 1 : 0
  tags = {
    Name = "prakash"
  }
}
resource "aws_nat_gateway" "nat" {
  count         = var.nat_count
  allocation_id = aws_eip.eip[count.index]
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
  count  = var.priv_sub_count ? 1 : 0
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Private-route"
  }
}
resource "aws_route" "private" {
  count                  = var.nat_count
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat[count.index].id
}
resource "aws_route_table_association" "private" {
  count          = var.priv_sub_count ? 1 : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
data "aws_security_group" "sg" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }
  filter {
    name   = "group-name"
    values = ["default"]
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
# data "aws_subnet_ids" "public" {
#   count  = var.pub_sub_count
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "public-subnet_${count.index}"
#   }
# }
# output "aws_subnet_ids" {
#   value = data.aws_subnet_ids.public
# }

# terraform {
#   required_providers {
#     grafana = {
#       source  = "grafana/grafana"
#       version = "1.6.0"
#     }
#   }
# }
# provider "grafana" {
#   url  = "http://ab9769ea21fd24ae69b755c54bc49b6f-227768245.ap-south-1.elb.amazonaws.com"
#   auth = "eyJrIjoiWDJRYkRlUm02MlZtMlpBUEt6UDV0TFdlSjZqeVZKNnIiLCJuIjoidGVycmFmb3JtIiwiaWQiOjF9"
# }
# resource "grafana_dashboard" "metrics" {
#   config_json = file("Final.json")
# }
# # resource "grafana_api_key" "foo" {
# #   name = "key_foo"
# #   role = "Viewer"
# # }
# #
# # resource "grafana_api_key" "bar" {
# #   name            = "key_bar"
# #   role            = "Admin"
# #   seconds_to_live = 30
# # }
# #
# #
# # output "api_key_foo_key_only" {
# #   value     = grafana_api_key.foo.key
# #   sensitive = true
# # }
# #
# # output "api_key_bar" {
# #   value = grafana_api_key.bar
# # }
# # resource "grafana_data_source" "influxdb" {
# #   type          = "influxdb"
# #   name          = "test_influxdb"
# #   url           = "http://influxdb.example.net:8086/"
# #   username      = "foo"
# #   password      = "bar"
# #
# # }

#
# #
# # resource "aws_iam_instance_profile" "node_group_instance_profile" {
# #   name_prefix = "EKSNodeGroupRole-"
# #   role        = aws_iam_role.node_group_role.name
# # }
# #
# # resource "aws_iam_role" "node_group_role" {
# #   name_prefix = "EKSNodeGroupRole-"
# #   path        = "/"
# #
# #   assume_role_policy = <<EOF
# # {
# #     "Version": "2012-10-17",
# #     "Statement": [
# #         {
# #             "Action": "sts:AssumeRole",
# #             "Principal": {
# #                "Service": "ec2.amazonaws.com"
# #             },
# #             "Effect": "Allow",
# #             "Sid": ""
# #         }
# #     ]
# # }
# # EOF
# # }
# # resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
# #   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# #   role       = aws_iam_role.node_group_role.name
# # }
# #
# # resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
# #   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# #   role       = aws_iam_role.node_group_role.name
# # }
resource "aws_eks_cluster" "eks" {
  name     = "EKS"
  role_arn = "arn:aws:iam::522820335540:role/AmazonEKSClusterServiceRole"
  version  = null
  # endpoint_private_access = var.cluster_endpoint_private_access
  # endpoint_public_access  = var.cluster_endpoint_public_access
  # public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }
}
resource "aws_eks_node_group" "ng" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "node_group"
  node_role_arn   = "arn:aws:iam::522820335540:role/AmazonEKSNodeRole"
  subnet_ids      = aws_subnet.public[*].id
  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
  update_config {
    max_unavailable = 1
  }
  # depends_on = [
  #   aws_iam_role_policy_attachment.Cluster_Policy
  # ]
}

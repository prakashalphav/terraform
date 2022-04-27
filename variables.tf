variable "vpc_cidr" {
}
variable "pub_sub_count" {
}
variable "priv_sub_count" {
}
variable "pub_instance_count" {
}
variable "priv_instance_count" {
}
variable "pub_instancename" {
}
variable "nat_count" {
}
variable "priv_instancename" {
}
variable "pub_instance_type" {
}
variable "priv_instance_type" {
}
# variable "cluster_endpoint_private_access" {
#   description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
#   type        = bool
#   default     = false
# }
#
# variable "cluster_endpoint_public_access" {
#   description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. When it's set to `false` ensure to have a proper private access with `cluster_endpoint_private_access = true`."
#   type        = bool
#   default     = true
# }
#
# variable "cluster_endpoint_public_access_cidrs" {
#   description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
#   type        = list(string)
#   default     = ["0.0.0.0/0"]
# }

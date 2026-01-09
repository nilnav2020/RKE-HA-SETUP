variable "region" {
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.0.0/24"
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI"
}

variable "key_name" {
  description = "Key pair for SSH"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "region" { type = string, default = "ap-south-1" }
variable "cluster_name" { type = string, default = "devops-demo" }
variable "instance_types" { type = list(string), default = ["t3.large", "t3.xlarge"] }
variable "desired_size" { type = number, default = 2 }

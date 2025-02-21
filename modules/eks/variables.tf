variable "app_name" {
  type = string
}

variable "iam_cluster_role_arn" {
  type = string
}

variable "iam_node_role_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "eks_node_group_max_size" {
  type = number
}

variable "eks_node_group_min_size" {
  type = number
}

variable "eks_node_group_desired_size" {
  type = number
}

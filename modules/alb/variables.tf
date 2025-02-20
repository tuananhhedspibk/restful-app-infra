variable "app_name" {
  type = string
}

variable "target_health_check_port" {
  type = number
}

variable "target_health_check_path" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

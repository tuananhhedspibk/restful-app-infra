output "lb_target_group_arn" {
  value = aws_lb_target_group.main.arn
}

output "http_listener_arn" {
  value = aws_lb_listener.main.arn
}

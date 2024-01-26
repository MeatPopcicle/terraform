output "security_group_lb" {
  value = aws_security_group.lb
}

output "security_group_hello_world_task" {
  value = aws_security_group.hello_world_task
}

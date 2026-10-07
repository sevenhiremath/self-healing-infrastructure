output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "service_url" {
  description = "Flask service URL through the ALB"
  value       = "http://${aws_lb.app.dns_name}"
}

output "availability_zones" {
  description = "Availability zones used by the application"
  value = [
    aws_subnet.public_a.availability_zone,
    aws_subnet.public_b.availability_zone
  ]
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.app.name
}

output "architecture" {
  description = "Human-readable Rung 4 architecture"
  value       = <<-EOT
  VPC
  ├── Public Subnet A (${aws_subnet.public_a.availability_zone})
  │   └── EC2 instances managed by ASG
  │
  ├── Public Subnet B (${aws_subnet.public_b.availability_zone})
  │   └── EC2 instances managed by ASG
  │
  ├── Internet Gateway
  ├── Public Route Table
  │
  ├── Application Load Balancer
  │   └── Target Group
  │       ├── HTTP :5000
  │       └── /health health check
  │
  └── Auto Scaling Group
      ├── min     = 2
      ├── desired = 2
      └── max     = 2
  EOT
}

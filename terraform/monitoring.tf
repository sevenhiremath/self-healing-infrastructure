resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "self-healing-infra"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Request Count"
          region = var.aws_region
          stat   = "Sum"
          period = 60
          view   = "timeSeries"

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.app.arn_suffix
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Healthy Hosts"
          region = var.aws_region
          stat   = "Maximum"
          period = 60
          view   = "timeSeries"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "LoadBalancer",
              aws_lb.app.arn_suffix,
              "TargetGroup",
              aws_lb_target_group.app.arn_suffix
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Unhealthy Hosts"
          region = var.aws_region
          stat   = "Maximum"
          period = 60
          view   = "timeSeries"

          metrics = [
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "LoadBalancer",
              aws_lb.app.arn_suffix,
              "TargetGroup",
              aws_lb_target_group.app.arn_suffix
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "EC2 CPU"
          region = var.aws_region
          stat   = "Average"
          period = 60
          view   = "timeSeries"

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization"
            ]
          ]
        }
      }
    ]
  })
}

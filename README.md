# Self-healing infrastructure

I built this project to understand what happens when an application process crashes or an EC2 instance becomes unhealthy.

The application is deliberately small: a Flask service with a health endpoint and an in-memory counter. Most of the work is in deploying it, checking its health and recovering from failures.

## How it works

```text
HTTP request
    |
Application Load Balancer
    |
Target group checks /health
    |
Two EC2 instances in an Auto Scaling Group
    |
Flask application supervised by systemd
```

Terraform creates a VPC, two public subnets in separate availability zones, security groups, an Application Load Balancer, a launch template and an Auto Scaling Group. The group currently keeps two instances running.

The launch template uses [user-data.sh](terraform/user-data.sh) to install Python and Flask, write the application and start a systemd service.

There are two recovery mechanisms:

- **Application process recovery:** systemd starts the process again after it exits. The service uses `Restart=always` with a three-second delay.
- **Instance recovery:** the Auto Scaling Group uses load-balancer health checks to identify and replace unhealthy instances. The load balancer sends requests to healthy targets.

[monitoring.tf](terraform/monitoring.tf) defines a CloudWatch dashboard for request count, healthy targets, unhealthy targets and CPU usage.

## Files worth reading

| File | Purpose |
| --- | --- |
| [app.py](app.py) | The small Flask application |
| [terraform/main.tf](terraform/main.tf) | Networking, load balancer and EC2 configuration |
| [terraform/user-data.sh](terraform/user-data.sh) | Instance setup and service installation |
| [terraform/monitoring.tf](terraform/monitoring.tf) | CloudWatch dashboard |
| [deploy/self-healing-infra.service.example](deploy/self-healing-infra.service.example) | Service template for a separate Linux installation |
| [scripts/measure_systemd_recovery.sh](scripts/measure_systemd_recovery.sh) | Process recovery measurement |
| [labs/nginx-backend/](labs/nginx-backend/) | Earlier WSL lab for Nginx routing and backend polling |

## Run the application locally

Python 3 and pip are required.

```bash
git clone https://github.com/sevenhiremath/self-healing-infrastructure.git
cd self-healing-infrastructure
python3 -m venv .venv
source .venv/bin/activate
python -m pip install flask
python app.py
```

On Windows, activate the environment with `.venv\Scripts\Activate.ps1`.

The application listens on port 5000:

| Route | Response |
| --- | --- |
| `/` | A greeting |
| `/health` | `OK` |
| `/counter` | An incrementing counter |

Running `python app.py` alone does not add automatic recovery. That comes from the systemd service on Linux.

## Review the AWS deployment

You need Terraform and AWS credentials configured locally. The default region is `ap-south-1`.

Before deploying, edit [main.tf](terraform/main.tf). The AMI ID, SSH key name and SSH source address are values from my environment. Use an Amazon Linux 2023 AMI in your region, your own key and an appropriate SSH address.

```bash
cd terraform
terraform init
terraform plan
```

Review the plan before running `terraform apply`. Deployment creates paid AWS resources, including an ALB and two EC2 instances. When you finish experimenting, review and run `terraform destroy` to remove them.

[outputs.tf](terraform/outputs.tf) exposes the load balancer address, service URL, availability zones and Auto Scaling Group name. The EC2 security group allows application traffic from the ALB security group.

## Measure process recovery

On a Linux machine where the service is already installed and running:

```bash
bash scripts/measure_systemd_recovery.sh self-healing-infra.service
```

The script kills the application's main process, waits for a new active process and writes a result to `docs/failure-tests.csv`. Run it only on your test service.

This measures process recovery. It does not measure successful HTTP responses, instance replacement time or end-to-end availability. The three-second restart delay is a setting, not a measured recovery result.

## What I learned

Process supervision and infrastructure health checks solve different problems. Restarting a crashed process can be quicker than replacing a whole instance, while instance replacement handles failures that process restarts cannot fix.

Using Terraform also made the network and deployment configuration easier to review than a list of manual console steps.

## Current scope

- The counter is held in memory. It resets after a process restart and is separate on each instance.
- The application uses Flask's development server. This is a learning deployment.
- `/health` checks that the application responds; it does not check a database or other dependencies.
- The published Terraform includes dashboard metrics. SNS alerts and Lambda remediation are not defined in this version.
- No measured uptime, zero-loss result or recovery-time benchmark is published here yet.

Terraform state, credentials, logs and the machine-specific service file are excluded from the repository.

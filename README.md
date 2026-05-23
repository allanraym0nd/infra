# Cloud Infrastructure Automation

Automated AWS infrastructure deployment using Terraform, Ansible, Python, and CloudWatch — with a full CI/CD pipeline via GitHub Actions.

## Architecture

GitHub Actions (CI/CD)
↓
Terraform
↓
AWS VPC + EC2 (t2.micro, Amazon Linux 2023)
↓
Ansible
↓
Python Health Reporter → CloudWatch Custom Metrics

## What This Does

- **Terraform** provisions a VPC, public subnet, EC2 instance, IAM role, security group, CloudWatch alarms, SNS alerts, and a dashboard
- **Ansible** configures the server — installs dependencies, creates a non-root user, hardens SSH, deploys the Python script, and sets up a cron job
- **Python script** collects CPU, memory, and disk metrics every 5 minutes and pushes them to CloudWatch as custom metrics
- **GitHub Actions** runs `terraform plan` on every PR and `terraform apply` on every push to master

## Security Decisions

- **SSH restricted to one IP** — security group allows port 22 from a single IP only
- **No root usage** — Ansible creates `appuser`, script runs as that user via cron
- **Least-privilege IAM** — EC2 role only allows `cloudwatch:PutMetricData` and `logs:*`, nothing else
- **No hardcoded credentials** — AWS credentials via GitHub secrets, local credentials via AWS CLI profile
- **Password authentication disabled** — SSH hardened via Ansible, key-only access enforced

## Usage

### Deploy
```bash
cd terraform
terraform init
terraform apply
```

### Configure server
```bash
ansible-playbook ansible/playbook.yml -i ansible/inventory.ini
```

### Verify metrics are being sent
```bash
ssh -i ~/.ssh/id_rsa ec2-user@<EC2_IP> "sudo su - appuser -c 'python3 /home/appuser/health_report.py'"
```

## Day-2 Operations

### Update the Python script
```bash
# Edit scripts/health_report.py locally, then rerun Ansible
ansible-playbook ansible/playbook.yml -i ansible/inventory.ini
```

### Update server packages
```bash
ansible-playbook ansible/playbook.yml -i ansible/inventory.ini --tags update
```

### Rotate AWS credentials
1. Generate new access keys in AWS IAM console
2. Update `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in GitHub secrets
3. Update `~/.aws/credentials` locally
4. Pipeline will use new credentials on next run

### Change SSH access IP
1. Update `my_ip` in `terraform.tfvars`
2. Run `terraform apply`

### View CloudWatch dashboard
```bash
cd terraform
terraform output cloudwatch_dashboard_url
```

### Tear down all infrastructure
```bash
cd terraform
terraform destroy
```

## Monitoring

Three CloudWatch alarms trigger SNS email alerts when:
- CPU exceeds 80% for 2 consecutive 2-minute periods
- Memory exceeds 80% for 2 consecutive 2-minute periods  
- Disk exceeds 80% for 2 consecutive 2-minute periods

Custom metrics namespace: `CustomMetrics/EC2`

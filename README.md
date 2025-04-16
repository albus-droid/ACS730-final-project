# ACS730 Final Project

## Two-Tier Web Application Automation with Terraform, Ansible, and GitHub Actions

This repository contains Infrastructure as Code (IaC) using Terraform, configuration management via Ansible, and automated CI/CD pipelines implemented through GitHub Actions to provision a scalable two-tier web application on AWS.

---

## Project Overview

This project demonstrates advanced DevOps practices:
- **Infrastructure Automation**: Terraform modules provision AWS infrastructure.
- **Configuration Management**: Ansible playbooks configure web servers.
- **CI/CD Integration**: GitHub Actions provide continuous integration and deployment automation, including security scans and environment-specific deployments.

---

## Repository Structure

```plaintext
.
├── ansible                   # Ansible configuration and playbooks
│   ├── aws_ec2.yaml          # Dynamic AWS inventory
│   └── webserver-setup.yml   # Ansible playbooks
├── modules                   # Terraform modules
│   ├── alb                   # ALB module
│   ├── ec2                   # EC2 instances module
│   └── vpc                   # VPC and networking module
├── dev                       # Terraform configuration for dev environment
├── staging                   # Terraform configuration for staging environment
├── prod                      # Terraform configuration for prod environment
├── .github                   # GitHub Actions workflows
│   └── workflows             
│       └── terraform.yml
└── README.md                 # This file
```

---

## Requirements

- **AWS Account**: Proper IAM permissions for creating resources.
- **Terraform**: v1.x or later
- **Ansible**: v2.14 or later
- **Python Dependencies**: `boto3`, `botocore` (install via `pip install boto3 botocore`)
- **GitHub Actions**: Enabled and configured secrets (AWS credentials, SSH keys)

---

## Deployment Instructions

### Step 1: Terraform Infrastructure Provisioning

Change directory into the target environment folder (dev, staging, prod):

```bash
cd dev
terraform init
terraform plan
terraform apply
```

### Step 2: Ansible Configuration

After provisioning your infrastructure, configure servers using Ansible:

```bash
cd ansible
ansible-playbook -i aws_ec2.yaml webserver-setup.yml --private-key <your-ssh-key.pem> -u ec2-user
```

*(Replace `<your-ssh-key.pem>` with the path to your SSH key.)*

---

## GitHub Actions CI/CD Pipeline

The GitHub Actions workflow performs the following:
- Static code analysis and security scans (TFLint, Trivy)
- Terraform plan/apply automatically upon merge to branches (`main`, `staging`, `dev`)
- Runs Ansible playbooks post Terraform deployment

**Ensure you have these secrets set in your GitHub repository settings:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` (if required)
- `SSH_KEY`

---

## Architecture Overview

The architecture includes:
- **VPC:** 4 public subnets, 2 private subnets, NAT Gateway
- **EC2:** 6 instances (1 Bastion host, 5 webservers)
- **ALB:** Application Load Balancer distributing HTTP traffic
- **ASG:** Auto Scaling Group for automatic scaling and high availability

---

## Cleanup

To avoid unnecessary AWS charges, clean up your environment after use:

```bash
terraform destroy
```

---

## Contributors

- [Albin Babu Varghese](https://github.com/albus-droid)
---

## License

This project was done adhering to [Seneca's Academic Integerity Policy](https://www.senecapolytechnic.ca/about/policies/academic-integrity-policy.html). 

---


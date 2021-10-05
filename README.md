# Drone

This repository contains Terraform infrastructure code which creates AWS resources required to run Drone CI/CD on AWS, including:

## Secrets stored in SSM

For security reasons some secrets are stored in SSM and should be created
before running terraform apply.

| Key | Value | 
|---|---|
| `drone/DRONE_DATABASE_SECRET` |  aws ssm put-parameter --name "drone/DRONE_DATABASE_SECRET" --type SecureString --region eu-central-1 --value $(openssl rand -hex 16) |
| `drone/DRONE_DATABASE_NAME` |  aws ssm put-parameter --name "drone/DRONE_DATABASE_NAME" --type SecureString --region eu-central-1 --value $(openssl rand -hex 8) |
-hex 16) |
| `drone/DRONE_DATABASE_USER_NAME` |  aws ssm put-parameter --name "drone/DRONE_DATABASE_USER_NAME" --type SecureString --region eu-central-1 --value $(openssl rand -hex 8) |
| `drone/DRONE_MONOREPO_GITHUB_TOKEN` | aws ssm put-parameter --name "drone/DRONE_MONOREPO_GITHUB_TOKEN" --type SecureString --region eu-central-1 --value "" |
| `drone/DRONE_GITHUB_CLIENT_ID` | aws ssm put-parameter --name "drone/DRONE_GITHUB_CLIENT_ID" --type SecureString --region eu-central-1 --value "" |
| `drone/DRONE_GITHUB_CLIENT_SECRET` | aws ssm put-parameter --name "drone/DRONE_GITHUB_CLIENT_SECRET" --type SecureString --region eu-central-1 --value "" |
| `drone/DRONE_LICENSE_KEY` | aws ssm put-parameter --name "drone/DRONE_LICENSE_KEY" --type SecureString --region eu-central-1 --value "" |

## Docker Images 

Looks at default for ecr image in current region and account for drone ci images
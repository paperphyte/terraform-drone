# Drone

This repository contains Terraform which creates AWS resources required to run Drone CI/CD on AWS ECS.

## Secrets stored in SSM

For security reasons some secrets are stored in SSM and should be created
before running terraform apply. To not have it in your history you can also
use the amazon console.

### Pre-filled

| Key | Value | 
|---|---|
| `/drone/db/password` |  aws ssm put-parameter --name "/drone/db/password" --type SecureString --region eu-north-1 --value $(openssl rand -hex 16) |
| `/drone/db/user_name` |  aws ssm put-parameter --name "/drone/db/user_name" --type SecureSt'ring --region eu-north-1 --value $(openssl rand -hex 8) |
| `drone/github/client_id` | aws ssm put-parameter --name "/drone/github/client_id" --type SecureString --region eu-north-1 --value "<CUSTOM VALUE>" |
| `/drone/github/client_secret` | aws ssm put-parameter --name "/drone/github/client_secret" --type SecureString --region eu-north-1 --value "<CUSTOM VALUE>" |
| `/drone/github/token` | aws ssm put-parameter --name "/drone/github/token" --type SecureString --region eu-north-1 --value "<CUSTOM VALUE>" |

### Pre-Created

These will be populated by terraform and overwritten but should be created as empty otherwise terraform apply will complain.

| Key | Value | 
|---|---|
| `/drone/server/rpc_secret` |  aws ssm put-parameter --name "/drone/server/rpc_secret" --type SecureString --region eu-north-1 --value "" |
| `/drone/server/amazon_secret` |  aws ssm put-parameter --name "/drone/server/amazon_secret" --type SecureString --region eu-north-1 --value "" |

## Source Images

Setup your local region with ecr images required by pulling them from original source and pushing them to your ecr region.

### Download & Compile Images

    1. docker pull bitsbeats/drone-tree-config
    2. docker pull drone/drone-runner-docker
    3. docker pull drone/drone
    4. fork: https://github.com/drone/drone-amazon-secrets and compile

### Login to ECR

    aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com

### Tag & Push

    1. docker tag <reference> <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/bitsbeats/drone-tree-config:v0.4.2
    1. docker push <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/bitsbeats/drone-tree-config:v0.4.2

### Secrets Plugin.

*note* secrets are default pulled from its own region so compile with region.

## Argument Reference

 * ```dns_root_name``` The root domain name such as example.com
 * ```dns_root_id``` The root domain zone name
 * ```drone_admin``` A default user to be admin of drone at creation
 * ```drone_user_filter``` Organisation or username to allow build from
 * ```allowed_cidr``` A cidr to limit access to drone user interface
 * ```versions``` (Optional) Version of drone task container image

note: source prior to v4.0.0 forked from: https://github.com/appleboy/drone-terraform-in-aws

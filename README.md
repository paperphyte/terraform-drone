# Drone

This repository contains Terraform infrastructure code which creates AWS resources required to run Drone CI/CD on AWS, including:

## Secrets stored in SSM

For security reasons some secrets are stored in SSM and should be created before running terraform apply.

### Pre-filled

| Key | Value | 
|---|---|
| `/drone/db/password` |  aws ssm put-parameter --name "/drone/db/password" --type SecureString --region eu-north-1 --value $(openssl rand -hex 16) |
| `/drone/db/user_name` |  aws ssm put-parameter --name "/drone/db/user_name" --type SecureSt'ring --region eu-north-1 --value $(openssl rand -hex 8) |
| `drone/github/client_id | aws ssm put-parameter --name "/drone/github/client_id" --type SecureString --region eu-north-1 --value "<CUSTOM VALUE>" |
| `/drone/github/client_secret` | aws ssm put-parameter --name "/drone/github/client_secret" --type SecureString --region eu-north-1 --value "<CUSTOM VALUE>" |
| `/drone/github/token` | aws ssm put-parameter --name "/drone/github/token" --type SecureString --region eu-north-1 --value "<CUSTOM VALUE>" |

### Pre-Created

These will be populated by terraform and overwritten but should be created as empty otherwise terraform apply will complain.

| Key | Value | 
|---|---|
| `/drone/server/rpc_secret |  aws ssm put-parameter --name "/drone/server/rpc_secret" --type SecureString --region eu-north-1 --value "" |
| `/drone/server/amazon_secret |  aws ssm put-parameter --name "/drone/server/amazon_secret" --type SecureString --region eu-north-1 --value "" |

## Docker Images 

Looks at default for ecr image in current region and account for drone ci images. Must be created prior to running the apply.


### Secrets Plugin.

*note* secrets are defaultly pulled from eu-west-1.
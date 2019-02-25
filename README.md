# terraform-drone

This repository contains Terraform infrastructure code which creates AWS resources
required to run Drone CI/CD on AWS, including:

 * Virtual Private Cloud (VPC)
 * SSL certificate using Amazon Certificate Manager (ACM)
 * Application Load Balancer (ALB)
 * Domain name using AWS Route53 which points to ALB
 * AWS Elastic Cloud Service (ECS) and AWS Fargate running Drone Server
 * Postgres flavoured RDS for build data

## Configuration

* Pre-existing AWS Route53 public zone

Choose an AWS region with both [AWS Fargate with Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html) and [AWS Service Discovery ](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html)

* Pre-existing EC2 key pair in AWS region
    * Import an existing AWS keypair: 

        $ terraform import aws_key_pair.ci_tool ci-tools

Note: Add public_key with content of keypair_public_key to terraform.tfstate after import.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | AWS region where the CI/CD gets deployed | string | `"eu-west-1"` | no |
| ci\_sub\_domain | Sub-domain / hostname to access ci | string | `"ci"` | no |
| db\_identifier | Identifier for RDS instance | string | `"ci-rds"` | no |
| db\_instance\_type | RDS instance types | string | `"db.t3.micro"` | no |
| db\_name | Database Name | string | `"ci_db"` | no |
| db\_storage\_size | Storage size of RDS instance in GB | string | `"10"` | no |
| db\_user | Database user name | string | `"ci_user"` | no |
| default\_ttl | Default ttl for domain records | string | `"300"` | no |
| drone\_agent\_max\_count | Max drone agents running. | string | `"2"` | no |
| drone\_agent\_min\_count | Min drone agens running. | string | `"2"` | no |
| drone\_agent\_port | Port of drone agent. | string | `"80"` | no |
| drone\_server\_port | Port of Drone Server | string | `"80"` | no |
| drone\_version | Ci Drone version. | string | `"1.0.0-rc.5"` | no |
| ecs\_cluster\_instance\_type | EC2 Instance Type. | string | `"t3.micro"` | no |
| ecs\_container\_cpu | Requested ecs container CPU | string | `"2000"` | no |
| ecs\_container\_memory | Requested ecs container memory | string | `"768"` | no |
| ecs\_max\_instances\_count | Max container instances running. | string | `"2"` | no |
| ecs\_min\_instances\_count | Min container instances running | string | `"2"` | no |
| ecs\_optimized\_ami |  | map | `<map>` | no |
| env\_drone\_admin | Drone privileged User | string | n/a | yes |
| env\_drone\_github\_organization | Registration is limited to users included in this list, or users that are members of organizations included in this list. | string | n/a | yes |
| env\_drone\_logs\_debug | String literal for verboser output from logs | string | `"false"` | no |
| env\_drone\_repo\_filter | whitliest repositories | string | n/a | yes |
| env\_drone\_webhook\_list | String literal value provides a comma-separated list of webhook endpoints | string | `"https://localhost?lis45"` | no |
| env\_github\_client | A string containing GitHub oauth Client ID. | string | n/a | yes |
| env\_github\_secret | A string containing GitHub oauth Client Secret. | string | n/a | yes |
| fargate\_task\_cpu | [Fargate task CPU and memory at the task level](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html) | string | `"256"` | no |
| fargate\_task\_memory | [Fargate task CPU and memory at the task level](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html) | string | `"512"` | no |
| ip\_access\_whitelist | White-listed cidr IP to access user interface. Allow from [Github Hook IP](https://api.github.com/meta) | list | `<list>` | no |
| keypair\_public\_key | Pubkey of A pre-existing keypair | string | n/a | yes |
| root\_domain | Pre-existing Route53 Hosted Zone domain | string | `"example.com"` | no |
| root\_domain\_zone\_id | Pre-existing Route53 Hosted Zone ID | string | n/a | yes |


## Outputs

| Name | Description |
|------|-------------|
| ci\_db\_root\_password | RDS database root user password |
| ci\_drone\_rpc\_secret | The RPC secret for drone server |
| ci\_server\_url | public accessible url of the ci |

## Tips

### Generate a graph over resources

    $ docker run --cap-add=SYS_ADMIN -it --rm -p 5000:5000 -v $(pwd):/workdir:ro 28mm/blast-radius

### Debug templates

Use null resource to debug json templates when failing. 

    resource "null_resource" "example" {
        triggers = {
            json = "${data.template_file.drone_server_task_definition.rendered}"
        }
    }

forked from: https://github.com/appleboy/drone-terraform-in-aws

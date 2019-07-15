# terraform-drone

This repository contains Terraform infrastructure code which creates AWS resources
required to run Drone CI/CD on AWS, including:

 * Virtual Private Cloud (VPC)
 * SSL certificate using Amazon Certificate Manager (ACM)
 * Domain name using AWS Route53 which points to ALB
 * AWS Elastic Cloud Service (ECS) and AWS Fargate running Drone Server
 * AWS Spot Fleet for EC2 instances in ECS
 * Postgres flavoured RDS for build data

## AWS Spot Fleet

AWS Spot fleet could be used to get more cheap agents in the cluster.

With **cluster_spot_instance_enabled** = 1/true the cluster will be seeded with 
spot instances until reaching number of **spot_fleet_target_capacity**.  

Set the **spot_fleet_bid_price** with a value corresponding to the region and
the **ecs_cluster_instance_type** in ecs cluster.

Combining **ecs_min_instances_count** and **ecs_max_instances_count** with the 
spot fleet will mix regular on-demand instances with spot priced instances.

Default is 1 on-demand instance and 1 spot fleet instance. When running with 
**ecs_min_instances_count** = 0 and **ecs_max_instances_count** = 0 the build 
agent cluster will be possible only with spot priced instances. This could
however mean that there sometimes are no agents.

## Configuration

Choose an AWS region with both [AWS Fargate with Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html) and [AWS Service Discovery ](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html)

See terraform.tfvars.sample for required configuration.

The **root_domain_zone_id** should be a pre-existing AWS Route53 public zone
The **keypair_public_key** can be from key generated locally from key.
OR imported with _terraform import aws_key_pair.ci_tool ci-tools_
WHEN imported remember to add _public_key_ to terraform.tfstate.

    "resources": {
      "aws_key_pair.ci_tool": {
        "type": "aws_key_pair",
        ..
        "primary": {
          ..
          "attributes": {
            ..
            "public_key": "<contents of keypair_public_key var>

## Inputs


| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | AWS region where the CI/CD gets deployed | string | `"eu-west-1"` | no |
| ci\_sub\_domain | Sub-domain / hostname to access ci | string | `"ci"` | no |
| cluster\_spot\_instance\_enabled | Seed Cluster with spot priced ec2 instances 0/1 true/false | string | `"1"` | no |
| db\_identifier | Identifier for RDS instance | string | `"ci-rds"` | no |
| db\_instance\_type | RDS instance types | string | `"db.t3.micro"` | no |
| db\_name | Database Name | string | `"ci_db"` | no |
| db\_storage\_size | Storage size of RDS instance in GB | string | `"10"` | no |
| db\_user | Database user name | string | `"ci_user"` | no |
| default\_ttl | Default ttl for domain records | string | `"300"` | no |
| drone\_agent\_max\_count | Max drone agents running. | string | `"2"` | no |
| drone\_agent\_min\_count | Min drone agens running. | string | `"1"` | no |
| drone\_version | Ci Drone version. | string | `"1.0.0-rc.5"` | no |
| ecs\_cluster\_instance\_type | EC2 Instance Type. | string | `"t3.micro"` | no |
| ecs\_container\_cpu | Requested ecs container CPU | string | `"2000"` | no |
| ecs\_container\_memory | Requested ecs container memory | string | `"768"` | no |
| ecs\_max\_instances\_count | Max container instances running. | string | `"1"` | no |
| ecs\_min\_instances\_count | Min container instances running | string | `"1"` | no |
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
| spot\_fleet\_allocation\_strategy | Strategy for seeding instances cross pools. Config only support one pool for now. | string | `"diversified"` | no |
| spot\_fleet\_bid\_price | Bid price for cluster resources | string | `"0.007"` | no |
| spot\_fleet\_target\_capacity | Target number of spot instances to seed the cluster with | string | `"1"` | no |
| spot\_fleet\_valid\_until | Amount of time a spot fleet bid should stay active | string | `"2022-02-22T02:02:02Z"` | no |


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

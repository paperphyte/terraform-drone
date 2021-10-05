
data "aws_ssm_parameter" "github_client_id" {
  name = "drone/DRONE_GITHUB_CLIENT_ID"
}

data "aws_ssm_parameter" "github_client_secret" {
  name = "drone/DRONE_GITHUB_CLIENT_SECRET"
}

data "aws_ssm_parameter" "github_webhook_cidr_blocks" {
  name = "drone/DRONE_GITHUB_WEBHOOK_CIDR"
}

data "aws_ssm_parameter" "drone_repo_filter" {
  name = "drone/DRONE_REPOSITORY_FILTER"
}

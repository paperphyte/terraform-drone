# ----------------------------------------
# AWS IAM Role
# ----------------------------------------
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.task_name}_ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ----------------------------------------
# AWS IAM Role Policy
# ----------------------------------------
resource "aws_iam_policy" "task_ssm_policy" {
  name = "${var.task_name}_task_ssm_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": "*",
       "Condition": {
          "StringEquals": {
              "kms:EncryptionContext:PARAMETER_ARN":"arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${upper(var.task_name)}_*"
          }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_kms" {
  role       = aws_iam_role.ecs_task_role.id
  policy_arn = aws_iam_policy.task_ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.ecs_task_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_ssm_read" {
  role       = aws_iam_role.ecs_task_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}


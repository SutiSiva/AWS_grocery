# CloudWatch Log Group für die GroceryMate App
resource "aws_cloudwatch_log_group" "grocerymate_lg" {
  name              = "/aws/grocerymate/app"
  retention_in_days = 14
}

# IAM Policy: Erlaubt der EC2 das Senden von Logs + Metrics
resource "aws_iam_policy" "cw_agent_policy" {
  name = "CloudWatchAgentPolicyForEC2"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      }
    ]
  })
}

# Policy an EC2-Rolle anhängen (FIXED)
resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.ec2_s3_role.id   # 🟢 WICHTIGER FIX!
  policy_arn = aws_iam_policy.cw_agent_policy.arn
}

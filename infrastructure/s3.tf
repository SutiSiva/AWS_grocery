# --- S3 Bucket für Avatare ---
resource "aws_s3_bucket" "avatars" {
  bucket_prefix = "grocerymate-avatars-"
  force_destroy = true

  tags = {
    Name        = "grocerymate-avatars"
    Environment = "Dev"
  }
}

# --- S3 Bucket Versionierung ---
resource "aws_s3_bucket_versioning" "avatars_versioning" {
  bucket = aws_s3_bucket.avatars.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- Blockiere öffentliche Zugriffe ---
resource "aws_s3_bucket_public_access_block" "avatars_block" {
  bucket                  = aws_s3_bucket.avatars.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- IAM Rolle für EC2 ---
resource "aws_iam_role" "ec2_s3_role" {
  name = "grocery-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# --- IAM Policy für S3 Zugriff ---
resource "aws_iam_role_policy" "s3_access_policy" {
  name = "grocery-ec2-s3-policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:*"]
      Resource = [
        aws_s3_bucket.avatars.arn,
        "${aws_s3_bucket.avatars.arn}/*"
      ]
    }]
  })
}

# --- IAM Instance Profile ---
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "grocery-ec2-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}

# Output
output "s3_bucket_name" {
  value = aws_s3_bucket.avatars.bucket
}
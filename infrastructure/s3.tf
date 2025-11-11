# --- S3 Bucket für Avatare ---
resource "aws_s3_bucket" "avatars" {
  bucket_prefix = "grocerymate-avatars-"
  force_destroy = true # erlaubt das Löschen beim Terraform destroy

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
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
}

# --- IAM Rolle für EC2 ---
resource "aws_iam_role" "ec2_s3_role" {
  name = "grocery-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# --- IAM Policy für S3 Zugriff ---
resource "aws_iam_role_policy" "s3_access_policy" {
  name = "grocery-ec2-s3-policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = [
          aws_s3_bucket.avatars.arn,
          "${aws_s3_bucket.avatars.arn}/*"
        ]
      }
    ]
  })
}

# --- IAM Instance Profile ---
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "grocery-ec2-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}

# --- EC2-Instanz mit IAM-Rolle verknüpfen ---
resource "aws_instance" "app" {
  ami                         = "ami-06ee6255945a96aba"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name                    = "suti-ec2-key"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "grocerymate-ec2"
  }
}

# --- Output für Bucketname ---
output "s3_bucket_name" {
  description = "Der Name des S3 Buckets"
  value       = aws_s3_bucket.avatars.bucket
}

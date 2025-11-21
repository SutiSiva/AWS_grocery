# -------------------------------
# RDS Subnet Group
# -------------------------------
resource "aws_db_subnet_group" "RDS_subnet_group" {
  name       = "main"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = { Name = "Terraform_RDS_subnet_group" }
}

# -------------------------------
# RDS Security Group
# -------------------------------
resource "aws_security_group" "rds_sg" {
  name   = "grocerymate-rds-sg"
  vpc_id = aws_vpc.sutivpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] # Nur EC2 darf rein
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "terraform-grocerymate-rds-sg" }
}

# -------------------------------
# RDS Instance
# -------------------------------
resource "aws_db_instance" "postgres" {
  identifier             = "database-terraform"
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20

  db_name  = "grocerymate_db"
  username = "grocery_user"
  password = "grocery_test"

  db_subnet_group_name   = aws_db_subnet_group.RDS_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true

  tags = { Name = "suti-terraform-rds" }
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

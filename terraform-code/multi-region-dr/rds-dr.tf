# Create RDS instances in primary region
provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

# primary database
resource "aws_db_instance" "primary" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

# replica database in secondary region
provider "aws" {
  alias  = "east"
  profile = "default"
  region  = "us-east-1"
}

resource "aws_db_instance" "replica" {
  provider              = aws.east
  allocated_storage     = 20
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t2.micro"
  username              = "foo"
  password              = "foobarbaz"
  parameter_group_name  = "default.mysql8.0"
  replicate_source_db   = aws_db_instance.primary.id
  skip_final_snapshot   = true
}

# DMS setup: replication instance
# DMS (Database Migration Service) replication instance can handle the data synchronization between the two RDS instances.
resource "aws_dms_replication_instance" "replication_instance" {
  allocated_storage            = 20
  replication_instance_class   = "dms.t2.micro"
  replication_instance_id      = "my-dms-replication-instance"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms_replication_subnet_group.id
  vpc_security_group_ids       = [aws_security_group.sg.id]
}

resource "aws_dms_replication_subnet_group" "dms_replication_subnet_group" {
  replication_subnet_group_id   = "dms-replication-group"
  replication_subnet_group_description = "DMS replication subnet group"
  subnet_ids = [aws_subnet.primary_subnet_id, aws_subnet.secondary_subnet_id]
}

resource "aws_subnet" "primary_subnet" {
  vpc_id = var.vpc_id_primary
  cidr_block = var.subnet_cidr_blocks[0]
}

resource "aws_subnet" "secondary_subnet" {
  vpc_id = var.vpc_id_secondary
  cidr_block = var.subnet_cidr_blocks[1]
}

resource "aws_security_group" "sg" {
  vpc_id = var.vpc_id_primary
}

# stack exports

output "primary_db_endpoint" {
  value = aws_db_instance.primary.endpoint
}

output "replica_db_endpoint" {
  value = aws_db_instance.replica.endpoint
}


locals {
  family         = "aurora-postgresql"
  rds_engine     = "aurora-postgresql"
  engine_version = "17.4"
}

resource "aws_security_group" "this" {
  name        = "${var.app_name}-${var.env_name}-postgres-sg"
  description = "${var.app_name}-${var.env_name}-postgres-sg"

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.env_name}-postgres-sg"
  }
}

resource "aws_security_group_rule" "private" {
  security_group_id = aws_security_group.this.id

  type        = "ingress"
  from_port   = var.port
  to_port     = var.port
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr]
  description = "Access from the same vpc"
}

resource "aws_security_group_rule" "proxy" {
  security_group_id = aws_security_group.this.id

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = var.proxy_security_group
  description              = "Access from proxy"
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name        = "${var.app_name}-${var.env_name}-postgres-subnet-group-${var.vpc_id}"
  description = "${var.app_name}-${var.env_name}-postgres-subnet-group-${var.vpc_id}"

  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.app_name}-${var.env_name}-postgres-subnet-group-${var.vpc_id}"
  }
}

resource "aws_db_parameter_group" "default" {
  name   = "${var.app_name}-${var.env_name}-db-pg"
  family = local.family

  tags = {
    Name = "${var.app_name}-${var.env_name}-db-pg"
  }
}

resource "aws_rds_cluster_parameter_group" "default" {
  name   = "${var.app_name}-${var.env_name}-rds-cluster-pg"
  family = local.family

  tags = {
    Name = "${var.app_name}-${var.env_name}-rds-cluster-pg"
  }

  parameter {
    name         = "time_zone"
    value        = "UTC"
    apply_method = "immediate"
  }

  parameter {
    name  = "slow_query_log"
    value = 1
  }

  parameter {
    name  = "general_log"
    value = 1
  }

  parameter {
    name  = "long_query_time"
    value = 5
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }
}

resource "aws_db_option_group" "main" {
  name = "${var.app_name}-${var.env_name}-db-option-group"

  engine_name          = "postresql"
  major_engine_version = local.engine_version
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.app_name}-${var.env_name}-postgresql-cluster"
  engine             = local.rds_engine
  engine_version     = local.engine_version

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.default.name
  db_subnet_group_name            = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.this.id]

  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.master_password

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.app_name}-${var.env_name}-postgres-final-snapshot"
}

resource "aws_rds_cluster_instance" "this" {
  identifier         = "${var.app_name}-${var.env_name}-postgres-identifier"
  cluster_identifier = aws_rds_cluster.this.id

  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  db_parameter_group_name = aws_db_parameter_group.default.name

  engine         = local.rds_engine
  instance_class = "db.t3.medium"
}

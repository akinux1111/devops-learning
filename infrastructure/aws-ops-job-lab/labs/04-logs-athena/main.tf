terraform {
  required_version = ">= 1.6"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}
provider "aws" {
  region = var.aws_region
  default_tags { tags = local.tags }
}
variable "aws_region" { type = string }
variable "name_prefix" { type = string }
locals {
  name = "${var.name_prefix}-04"
  tags = { Project = var.name_prefix, Lab = "04", ManagedBy = "Terraform" }
}
resource "random_id" "suffix" { byte_length = 4 }
resource "aws_s3_bucket" "logs" {
  bucket        = "${local.name}-logs-${random_id.suffix.hex}"
  force_destroy = true
}
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "expire-lab-logs"
    status = "Enabled"
    filter { prefix = "logs/" }
    expiration { days = 7 }
  }
}
resource "aws_s3_object" "sample" {
  bucket  = aws_s3_bucket.logs.id
  key     = "logs/year=2026/month=09/day=23/access.log"
  content = "2026-09-23T10:00:00Z,GET,/health,200,12\n2026-09-23T10:01:00Z,GET,/api,500,831\n2026-09-23T10:02:00Z,GET,/api,500,902\n"
}
resource "aws_glue_catalog_database" "logs" { name = replace("${local.name}_logs", "-", "_") }
resource "aws_glue_catalog_table" "access" {
  name          = "access_logs"
  database_name = aws_glue_catalog_database.logs.name
  table_type    = "EXTERNAL_TABLE"
  parameters    = { EXTERNAL = "TRUE", "skip.header.line.count" = "0" }
  storage_descriptor {
    location      = "s3://${aws_s3_bucket.logs.id}/logs/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters            = { "field.delim" = "," }
    }
    columns {
      name = "event_time"
      type = "string"
    }
    columns {
      name = "method"
      type = "string"
    }
    columns {
      name = "path"
      type = "string"
    }
    columns {
      name = "status"
      type = "int"
    }
    columns {
      name = "latency_ms"
      type = "int"
    }
  }
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
}
resource "aws_glue_partition" "sample" {
  database_name    = aws_glue_catalog_database.logs.name
  table_name       = aws_glue_catalog_table.access.name
  partition_values = ["2026", "09", "23"]
  storage_descriptor {
    location      = "s3://${aws_s3_bucket.logs.id}/logs/year=2026/month=09/day=23/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters            = { "field.delim" = "," }
    }
    columns {
      name = "event_time"
      type = "string"
    }
    columns {
      name = "method"
      type = "string"
    }
    columns {
      name = "path"
      type = "string"
    }
    columns {
      name = "status"
      type = "int"
    }
    columns {
      name = "latency_ms"
      type = "int"
    }
  }
}
resource "aws_athena_workgroup" "lab" {
  name          = local.name
  force_destroy = true
  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.logs.id}/athena-results/"
    }
  }
}
output "workgroup" { value = aws_athena_workgroup.lab.name }
output "database" { value = aws_glue_catalog_database.logs.name }
output "query_output" { value = "s3://${aws_s3_bucket.logs.id}/athena-results/" }
output "log_bucket" { value = aws_s3_bucket.logs.id }

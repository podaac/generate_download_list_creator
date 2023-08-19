terraform {
  backend "s3" {
    encrypt = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  default_tags {
    tags = local.default_tags
  }
  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_ecr_repository" "download_list_creator" {
  name = "${var.prefix}-download-list-creator"
}

data "aws_kms_key" "aws_s3" {
  key_id = "alias/aws/s3"
}

data "aws_s3_bucket" "s3_download_lists" {
  bucket = var.prefix
}

data "aws_security_groups" "vpc_default_sg" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.application_vpc.id]
  }
}

data "aws_sns_topic" "batch_failure_topic" {
  name = "${var.prefix}-batch-job-failure"
}

data "aws_sqs_queue" "download_lists" {
  name = "${var.prefix}-download-lists"
}

data "aws_sqs_queue" "pending_jobs_aqua" {
  name = "${var.prefix}-pending-jobs-aqua.fifo"
}

data "aws_sqs_queue" "pending_jobs_terra" {
  name = "${var.prefix}-pending-jobs-terra.fifo"
}

data "aws_sqs_queue" "pending_jobs_viirs" {
  name = "${var.prefix}-pending-jobs-viirs.fifo"
}

data "aws_subnet" "private_application_subnet" {
  for_each = toset(data.aws_subnets.private_application_subnets.ids)
  id       = each.value
}

data "aws_subnets" "private_application_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.application_vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["Private application*"]
  }
}

data "aws_vpc" "application_vpc" {
  tags = {
    "Name" : "Application VPC"
  }
}

# Local variables
locals {
  account_id = data.aws_caller_identity.current.account_id
  default_tags = length(var.default_tags) == 0 ? {
    application : var.app_name,
    environment : var.environment,
    version : var.app_version
  } : var.default_tags
}
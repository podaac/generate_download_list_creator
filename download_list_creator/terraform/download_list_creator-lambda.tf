# AWS Lambda function
resource "aws_lambda_function" "aws_lambda_download_list_creator" {
  image_uri     = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.prefix}-download-list-creator:latest"
  function_name = "${var.prefix}-download-list-creator"
  role          = aws_iam_role.aws_lambda_dlc_execution_role.arn
  package_type  = "Image"
  memory_size   = 3072
  timeout       = 900
}

# AWS Lambda execution role & policy
resource "aws_iam_role" "aws_lambda_dlc_execution_role" {
  name = "${var.prefix}-lambda-dlc-execution-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/NGAPShRoleBoundary"
}

resource "aws_iam_role_policy_attachment" "aws_lambda_dlc_execution_role_policy_attach" {
  role       = aws_iam_role.aws_lambda_dlc_execution_role.name
  policy_arn = aws_iam_policy.aws_lambda_dlc_execution_policy.arn
}

resource "aws_iam_policy" "aws_lambda_dlc_execution_policy" {
  name        = "${var.prefix}-lambda-dlc-execution-policy"
  description = "Upload files to bucket and send messages to queue."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCreatePutLogs",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Sid" : "AllowPutObject",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject"
        ],
        "Resource" : "${aws_s3_bucket.aws_s3_bucket_dlc.arn}"
      },
      {
        "Sid" : "AllowSendMessage",
        "Effect" : "Allow",
        "Action" : [
          "sqs:SendMessage"
        ],
        "Resource" : "${aws_sqs_queue.aws_sqs_queue_dlc.arn}"
      }
    ]
  })
}

# S3 bucket to hold text files
resource "aws_s3_bucket" "aws_s3_bucket_dlc" {
  bucket = "${var.prefix}-download-lists"
  tags   = { Name = "${var.prefix}-download-lists" }
}

resource "aws_s3_bucket_public_access_block" "aws_s3_bucket_dlc_public_block" {
  bucket                  = aws_s3_bucket.aws_s3_bucket_dlc.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "aws_s3_bucket_dlc_ownership" {
  bucket = aws_s3_bucket.aws_s3_bucket_dlc.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "aws_s3_bucket_dlc_encryption" {
  bucket = aws_s3_bucket.aws_s3_bucket_dlc.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "aws/s3"
    }
  }
}

# SQS Queue
resource "aws_sqs_queue" "aws_sqs_queue_dlc" {
  name                       = "${var.prefix}-download-lists"
  visibility_timeout_seconds = 300
  sqs_managed_sse_enabled    = true
}

resource "aws_sqs_queue_policy" "aws_sqs_queue_policy_dlc" {
  queue_url = aws_sqs_queue.aws_sqs_queue_dlc.id
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Id" : "__default_policy_ID",
    "Statement" : [
      {
        "Sid" : "__owner_statement",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${local.account_id}"
        },
        "Action" : [
          "SQS:*"
        ],
        "Resource" : "${aws_sqs_queue.aws_sqs_queue_dlc.arn}"
      }
    ]
  })
}
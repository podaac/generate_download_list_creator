# S3 bucket to hold text files
resource "aws_s3_bucket" "aws_s3_bucket_dlc" {
  bucket = "${var.prefix}-download-lists"
  tags   = { Name = "${var.prefix}-download-lists" }
}

resource "aws_s3_bucket_public_access_block" "aws_s3_bucket_idl_server_public_block" {
  bucket                  = aws_s3_bucket.aws_s3_bucket_dlc.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "aws_s3_bucket_idl_server_ownership" {
  bucket = aws_s3_bucket.aws_s3_bucket_dlc.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# SQS Queue
resource "aws_sqs_queue" "aws_sqs_queue_dlc" {
  name                       = "${var.prefix}-donwload-lists"
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
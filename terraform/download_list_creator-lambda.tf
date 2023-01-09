# AWS Lambda function
resource "aws_lambda_function" "aws_lambda_download_list_creator" {
  image_uri     = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.prefix}-download-list-creator:latest"
  function_name = "${var.prefix}-download-list-creator"
  role          = aws_iam_role.aws_lambda_dlc_execution_role.arn
  package_type  = "Image"
  memory_size   = 256
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
        "Sid" : "AllowListBucket",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : "${aws_s3_bucket.aws_s3_bucket_dlc.arn}"
      },
      {
        "Sid" : "AllowGetPutObject",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource" : "${aws_s3_bucket.aws_s3_bucket_dlc.arn}/*"
      },
      {
        "Sid" : "AllowKMSKeyAccess",
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        "Resource" : "${data.aws_kms_key.aws_s3.arn}"
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

# EventBridge schedules
# MODIS Aqua
resource "aws_scheduler_schedule" "aws_schedule_dlc_aqua" {
  name       = "${var.prefix}-dlc-modis-aqua"
  group_name = "default"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "cron(0 * * * ? *)"
  target {
    arn      = aws_lambda_function.aws_lambda_download_list_creator.arn
    role_arn = aws_iam_role.aws_eventbridge_dlc_execution_role.arn
    input = jsonencode({
    "search_pattern" : "${var.aqua_search_pattern}",
    "processing_type" : "${var.aqua_processing_type}",
    "processing_level" : "${var.processing_level}",
    "num_days_back" : "${var.num_days_back}",
    "granule_start_date" : "${var.granule_start_date}",
    "granule_end_date" : "${var.granule_end_date}",
    "naming_pattern_indicator" : "${var.naming_pattern_indicator}",
    "account" : "${local.account_id}",
    "region" : "${var.aws_region}",
    "prefix": "${var.prefix}"
  })
  }
}

# MODIS Terra
resource "aws_scheduler_schedule" "aws_schedule_dlc_terra" {
  name       = "${var.prefix}-dlc-modis-terra"
  group_name = "default"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "cron(5 * * * ? *)"
  target {
    arn      = aws_lambda_function.aws_lambda_download_list_creator.arn
    role_arn = aws_iam_role.aws_eventbridge_dlc_execution_role.arn
    input = jsonencode({
    "search_pattern" : "${var.terra_search_pattern}",
    "processing_type" : "${var.terra_processing_type}",
    "processing_level" : "${var.processing_level}",
    "num_days_back" : "${var.num_days_back}",
    "granule_start_date" : "${var.granule_start_date}",
    "granule_end_date" : "${var.granule_end_date}",
    "naming_pattern_indicator" : "${var.naming_pattern_indicator}",
    "account" : "${local.account_id}",
    "region" : "${var.aws_region}",
    "prefix": "${var.prefix}"
  })
  }
}

# VIIRS
resource "aws_scheduler_schedule" "aws_schedule_dlc_viirs" {
  name       = "${var.prefix}-dlc-modis-viirs"
  group_name = "default"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "cron(10 * * * ? *)"
  target {
    arn      = aws_lambda_function.aws_lambda_download_list_creator.arn
    role_arn = aws_iam_role.aws_eventbridge_dlc_execution_role.arn
    input = jsonencode({
    "search_pattern" : "${var.viirs_search_pattern}",
    "processing_type" : "${var.viirs_processing_type}",
    "processing_level" : "${var.processing_level}",
    "num_days_back" : "${var.num_days_back}",
    "granule_start_date" : "${var.granule_start_date}",
    "granule_end_date" : "${var.granule_end_date}",
    "naming_pattern_indicator" : "${var.naming_pattern_indicator}",
    "account" : "${local.account_id}",
    "region" : "${var.aws_region}",
    "prefix": "${var.prefix}"
  })
  }
}

# EventBridge execution role and policy
resource "aws_iam_role" "aws_eventbridge_dlc_execution_role" {
  name = "${var.prefix}-eventbridge-dlc-execution-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "scheduler.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/NGAPShRoleBoundary"
}

resource "aws_iam_role_policy_attachment" "aws_eventbridge_dlc_execution_role_policy_attach" {
  role       = aws_iam_role.aws_eventbridge_dlc_execution_role.name
  policy_arn = aws_iam_policy.aws_eventbridge_dlc_execution_policy.arn
}

resource "aws_iam_policy" "aws_eventbridge_dlc_execution_policy" {
  name        = "${var.prefix}-eventbridge-dlc-execution-policy"
  description = "Allow EventBridge to invoke a Lambda function."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowInvokeLambda",
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Resource" : "${aws_lambda_function.aws_lambda_download_list_creator.arn}"
      }
    ]
  })
}
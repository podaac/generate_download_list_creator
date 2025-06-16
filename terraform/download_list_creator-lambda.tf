# AWS Lambda function
resource "aws_lambda_function" "aws_lambda_download_list_creator" {
  image_uri     = "${data.aws_ecr_repository.download_list_creator.repository_url}:latest"
  function_name = "${var.prefix}-download-list-creator"
  role          = aws_iam_role.aws_lambda_dlc_execution_role.arn
  package_type  = "Image"
  memory_size   = 2048
  timeout       = 900
  ephemeral_storage {
    size = 2048 # Min 512 MB and the Max 10240 MB
  }
  vpc_config {
    subnet_ids         = data.aws_subnets.private_application_subnets.ids
    security_group_ids = data.aws_security_groups.vpc_default_sg.ids
  }
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
        "Sid" : "AllowVPCAccess",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface"
        ],
        "Resource" : concat([for subnet in data.aws_subnet.private_application_subnet : subnet.arn], ["arn:aws:ec2:${var.aws_region}:${local.account_id}:*/*"])
      },
      {
        "Sid" : "AllowVPCDelete",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteNetworkInterface"
        ],
        "Resource" : "arn:aws:ec2:${var.aws_region}:${local.account_id}:*/*"
      },
      {
        "Sid" : "AllowVPCDescribe",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeNetworkInterfaces",
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowListBucket",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : "${data.aws_s3_bucket.s3_download_lists.arn}"
      },
      {
        "Sid" : "AllowGetPutObject",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource" : "${data.aws_s3_bucket.s3_download_lists.arn}/*"
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
        "Sid" : "AllowSendMessageDLC",
        "Effect" : "Allow",
        "Action" : [
          "sqs:SendMessage"
        ],
        "Resource" : "${data.aws_sqs_queue.download_lists.arn}"
      },
      {
        "Sid" : "AllowSQSAccessPJ",
        "Effect" : "Allow",
        "Action" : [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Resource" : [
          "${data.aws_sqs_queue.pending_jobs_aqua.arn}",
          "${data.aws_sqs_queue.pending_jobs_terra.arn}",
          "${data.aws_sqs_queue.pending_jobs_viirs.arn}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:ListTopics"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish"
        ],
        "Resource" : "${data.aws_sns_topic.batch_failure_topic.arn}"
      }
    ]
  })
}

# EventBridge schedules
# MODIS Aqua
resource "aws_scheduler_schedule" "aws_schedule_dlc_aqua" {
  name       = "${var.prefix}-dlc-aqua"
  group_name = "default"
  state               = "DISABLED"
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
      "creation_date" : "${var.creation_date}",
      "search_filter": "${var.aqua_search_filter}",
      "account" : "${local.account_id}",
      "region" : "${var.aws_region}",
      "prefix" : "${var.prefix}"
    })
  }
}

# MODIS Terra
resource "aws_scheduler_schedule" "aws_schedule_dlc_terra" {
  name       = "${var.prefix}-dlc-terra"
  group_name = "default"
  state               = "DISABLED"
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
      "creation_date" : "${var.creation_date}",
      "search_filter": "${var.terra_search_filter}",
      "account" : "${local.account_id}",
      "region" : "${var.aws_region}",
      "prefix" : "${var.prefix}"
    })
  }
}

# VIIRS
resource "aws_scheduler_schedule" "aws_schedule_dlc_viirs" {
  name       = "${var.prefix}-dlc-viirs"
  group_name = "default"
  state               = "DISABLED"
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
      "creation_date" : "${var.creation_date}",
      "search_filter": "${var.viirs_search_filter}",
      "account" : "${local.account_id}",
      "region" : "${var.aws_region}",
      "prefix" : "${var.prefix}"
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
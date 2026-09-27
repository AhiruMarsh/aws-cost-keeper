# ====================================================
# Cost keeper (Lambda function / Budget)
# ====================================================
locals {
  name_prefix = "${var.system_name}-${var.env_name}"

  # Lambda runtime
  lambda_function_name = "${local.name_prefix}-server"
  lambda_runtime       = "python3.15"
  lambda_architecture  = "arm64"
  lambda_pip_platform  = "manylinux2014_aarch64"

  # Lambda package (built by terraform apply)
  lambda_app_dir      = abspath("${path.module}/../../../app")
  lambda_src_dir      = "${local.lambda_app_dir}/src"
  lambda_requirements = "${local.lambda_app_dir}/requirements-lambda.txt"
  # stateに保存されるパスは相対パスにする
  # (Terraform Cloud等ではRunごとに作業ディレクトリの絶対パスが変わり、毎回差分が出るため)
  lambda_build_dir     = "${path.module}/.build"
  lambda_zip_path      = "${local.lambda_build_dir}/lambda.zip"
  lambda_build_abs_dir = abspath(local.lambda_build_dir)
  lambda_package_dir   = "${local.lambda_build_abs_dir}/package"

  # ソースコード・依存関係・ランタイムから算出したハッシュ
  # zipファイル自体のハッシュではなく入力値から算出することで、
  # plan/applyが別環境で実行される場合 (Terraform Cloud等) でも差分が安定する
  lambda_source_hash = base64sha256(join("", concat(
    [for f in sort(fileset(local.lambda_src_dir, "**/*.py")) : "${f}:${filesha256("${local.lambda_src_dir}/${f}")}"],
    [filesha256(local.lambda_requirements)],
    [local.lambda_runtime, local.lambda_architecture],
  )))
}

data "aws_caller_identity" "current" {}

# ----------------------------------------------------
# AWS Budgets
# ----------------------------------------------------
resource "aws_budgets_budget" "main" {
  name        = local.name_prefix
  budget_type = "COST"
  time_unit   = "MONTHLY"

  auto_adjust_data {
    auto_adjust_type = "HISTORICAL"

    historical_options {
      budget_adjustment_period = 6
    }
  }

  cost_types {
    include_credit             = false
    include_discount           = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = false
    include_subscription       = true
    include_support            = true
    include_tax                = false
    include_upfront            = false
    use_amortized              = false
    use_blended                = false
  }
}

# ----------------------------------------------------
# Lambda package (pip install + zip)
# ----------------------------------------------------
resource "terraform_data" "lambda_package" {
  # zipはapply実行環境にしか存在しないため、パスが変わった場合も必ず再ビルドする
  triggers_replace = [local.lambda_source_hash, local.lambda_zip_path]
  input            = local.lambda_zip_path

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      rm -rf "${local.lambda_build_abs_dir}"
      mkdir -p "${local.lambda_package_dir}"

      python3 -m pip install \
        --quiet \
        --no-cache-dir \
        --disable-pip-version-check \
        --target "${local.lambda_package_dir}" \
        --platform "${local.lambda_pip_platform}" \
        --implementation cp \
        --python-version "${trimprefix(local.lambda_runtime, "python")}" \
        --only-binary=:all: \
        -r "${local.lambda_requirements}"

      cp -R "${local.lambda_src_dir}/." "${local.lambda_package_dir}/"
      find "${local.lambda_package_dir}" -type d -name "__pycache__" -prune -exec rm -rf {} +

      cd "${local.lambda_package_dir}"
      python3 -m zipfile -c "${abspath(local.lambda_zip_path)}" .
    EOT
  }
}

# ----------------------------------------------------
# Lambda function
# ----------------------------------------------------
data "aws_iam_policy_document" "app_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = local.lambda_function_name
  assume_role_policy = data.aws_iam_policy_document.app_assume_role.json
}

resource "aws_iam_role_policy_attachment" "app" {
  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess",
  ])

  role       = aws_iam_role.app.name
  policy_arn = each.value
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_lambda_function" "app" {
  function_name = local.lambda_function_name
  description   = "AWS Cost keeper"

  role             = aws_iam_role.app.arn
  handler          = "main.lambda_handler"
  runtime          = local.lambda_runtime
  architectures    = [local.lambda_architecture]
  timeout          = 10
  filename         = terraform_data.lambda_package.output
  source_code_hash = local.lambda_source_hash

  environment {
    variables = {
      AWS_BUDGET_NAME     = aws_budgets_budget.main.name
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.app,
    aws_cloudwatch_log_group.app,
  ]
}

# ----------------------------------------------------
# EventBridge Scheduler
# ----------------------------------------------------
data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${local.name_prefix}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
}

data "aws_iam_policy_document" "scheduler_iam" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.app.arn,
      "${aws_lambda_function.app.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "scheduler" {
  name = "${local.name_prefix}-scheduler"

  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_iam.json
}

resource "aws_scheduler_schedule" "scheduler" {
  name                = "${local.name_prefix}-scheduler"
  schedule_expression = var.schedule_expression
  state               = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.app.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}

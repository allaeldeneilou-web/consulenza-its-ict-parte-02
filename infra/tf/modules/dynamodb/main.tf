variable "environment" {
  type = string
}

variable "prefix" {
  type = string
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "iscrizioni_kms" {
  statement {
    sid    = "EnableAccountRootPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "iscrizioni" {
  count                   = var.environment != "dev" ? 1 : 0
  description             = "CMK per la tabella iscrizioni del portale ITS"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.iscrizioni_kms.json

  tags = {
    Owner            = "ITS-ICT"
    Repository       = "consulenza-its-ict"
    TechnicalContact = "allaeldene.ilou"
  }
}

resource "aws_kms_alias" "iscrizioni" {
  count         = var.environment != "dev" ? 1 : 0
  name          = "alias/${var.prefix}-iscrizioni"
  target_key_id = aws_kms_key.iscrizioni[0].key_id
}

resource "aws_dynamodb_table" "iscrizioni" {
  count        = var.environment != "dev" ? 1 : 0
  name         = "${var.prefix}-iscrizioni"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "iscrizioneId"

  attribute {
    name = "iscrizioneId"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.iscrizioni[0].arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Progetto         = "portale-its"
    Ambiente         = var.environment
    Owner            = "ITS-ICT"
    Repository       = "consulenza-its-ict"
    TechnicalContact = "allaeldene.ilou"
  }
}

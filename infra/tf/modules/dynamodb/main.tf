variable "environment" {
  type = string
}

variable "prefix" {
  type = string
}

data "aws_caller_identity" "current" {}

# This is the standard administrative policy for the CMK: the root principal
# delegates key management to the account through IAM policies.
# Generic IAM checks do not distinguish this case from an application policy.
# checkov:skip=CKV_AWS_109:policy KMS standard necessaria per mantenere la gestione della CMK nell'account
# checkov:skip=CKV_AWS_111:policy KMS standard necessaria per mantenere la gestione della CMK nell'account
# checkov:skip=CKV_AWS_356:Resource '*' is required by KMS key policy syntax
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

locals {
  kms_keys = var.environment != "dev" ? { current = true } : {}
}

resource "aws_kms_key" "iscrizioni" {
  for_each                = local.kms_keys
  description             = "CMK per la tabella iscrizioni del portale ITS"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    Owner            = "ITS-ICT"
    Repository       = "consulenza-its-ict"
    TechnicalContact = "allaeldene.ilou"
  }
}

resource "aws_kms_key_policy" "iscrizioni" {
  for_each = local.kms_keys
  key_id   = aws_kms_key.iscrizioni[each.key].id
  policy   = data.aws_iam_policy_document.iscrizioni_kms.json
}

resource "aws_kms_alias" "iscrizioni" {
  for_each      = local.kms_keys
  name          = "alias/${var.prefix}-iscrizioni"
  target_key_id = aws_kms_key.iscrizioni[each.key].key_id
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
    kms_key_arn = aws_kms_key.iscrizioni["current"].arn
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

/* プライベートバケットの定義 */
resource "aws_s3_bucket" "private" {
    bucket = "private-pragmatic-terraform" /* バケット名は全世界で一意制約 */
    versioning { /* これを設定しておくと以前のバージョンに復元できる */
        enabled = true
    }
    server_side_encryption_configuration { /* 暗号化を有効にする、オブジェクト保存時に暗号化 */
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}

/* パブリックバケットの定義 */
resource "aws_s3_bucket" "public" {
    bucket = "public-pragmatic-terraform"
    acl = "public-read" /* アクセス権限の設定（ACLのデフォルトはprivateなので明示） */
    cors_rule { /* CORS(Cross-Origin Resource Sharing) */
        allowed_origins = ["https://example.com"]
        allowed_methods = ["GET"]
        allowed_headers = ["*"]
        max_age_seconds = 3000
    }
}

/* ブロックパブリックアクセスの定義 */
/* 予期しないオブジェクトの公開を抑止するための設定 */
resource "aws_s3_bucket_public_access_block" "private" {
    bucket = aws_s3_bucket.private.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

/* ログバケットの定義 */
resource "aws_s3_bucket" "alb_log" { /* ALB用のログ定義 */
    bucket = "alb-log-pragmatic-terraform"
    lifecycle_rule {
        enabled = true
        expiration {
            days = "180"
        }
    }
}

/* バケットポリシーの定義 */
/* ALBなどのAWSサービスからS3に書き込みする際に必要なアクセス権限 */
resource "aws_s3_bucket_policy" "alb_log" {
    bucket = aws_s3_bucket.alb_log.id
    policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
    statement {
        effect = "Allow"
        actions = ["s3:PutObject"]
        resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]
        principals {
            type = "AWS"
            identifiers = ["582318560864"] /* ここの数字はリージョンごとで違う */
        }
    }
}

/* ########################### MEMO ########################### */
/* バケット強制削除（基本的にバケットが空でないとTerraformから削除できない） */
/*
resource "aws_s3_bucket" "force_destory" {
    bucket = "force-desstroy-pragmatic-terraform"
    force_destory = true
}
*/

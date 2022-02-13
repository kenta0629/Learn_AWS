module "describe_regions_for_ec2" {
    source = "./iam_role"
    name = "describe_regions_for_ec2"
    identifier = "ec2.amazonaws.com"
    policy = data.aws_iam_policy_document.allow_describe_regions.json
}

/* ポリシードキュメント(tfで書くとこうなる) */
data "aws_iam_policy_document" "allow_describe_regions" {
    statement {
        effect = "Allow"
        actions = ["ec2:DescribeRegions"]
        resources = ["*"]
    }
}

/* ポリシードキュメントを保持するリソース */
resource "aws_iam_policy" "example" {
    name = "example"
    policy = data.aws_iam_policy_document.allow_describe_regions.json
}

/* サービス権限付与するためのロール設定（信頼ポリシー） */
data "aws_iam_policy_document" "ec2_assume_role" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"] /* ec2にのみロールが適用される */
        }
    }
}

/* IAMロールの設定 */
resource "aws_iam_role" "example" {
    name = "example"
    assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json /* 信頼ポリシーの設定 */
}

/* IAMロールをアタッチ */
resource "aws_iam_role_policy_attachment" "example" {
    role = aws_iam_role.example.name
    policy_arn = aws_iam_role.example.arn
}

/* ######################### ファイアウォール ######################### */
/* サブネットレベル：ネットワークACL */
/* インスタンスレベル：セキュリティグループ（OSに到達する前にネットワークレベルでパケットをフィルタリングできる） */

variable "name" {} /* 型が明示されていない場合はany型になる */
variable "vpc_id" {}
variable "port" {}
variable "cidr_blocks" {
    type = list(string)
}

/* セキュリティグループ */
resource "aws_security_group" "default" {
    name = var.name
    vpc_id = var.vpc_id
}

/* ルール設定（インバウンドルール） */
resource "aws_security_group_rule" "ingress" {
    type = "ingress" /* ingressにするとインバウンドルールになる */
    from_port = var.port /* 設定ポートからの通信のみ許可 */
    to_port = var.port
    protocol = "tcp"
    cidr_blocks = var.cidr_blocks
    security_group_id = aws_security_group.default.id
}

/* ルール設定（アウトバウンドルール） */
resource "aws_security_group_rule" "egress" {
    type = "egress" /* egressにするとアウトバウンドルールになる */
    from_port = 0 /* すべての通信許可 */
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.default.id
}

output "security_group_id" {
    value = aws_security_group.default.id
}

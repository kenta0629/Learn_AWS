/* ######################### ALB設定 ######################### */
resource "aws_lb" "example" {
    name = "example"
    load_balancer_type = "application" /* applicationはALB(Application Load Balancer)、networkはNLB(Network Load Balancer)  */
    internal = false /* インターネット向けならfalse、VPC内部向けならtrue */
    idle_timeout = 60 /* デフォルトは60秒 */
    enable_deletion_protection = true /* 削除保護 */
    subnets = [ /* 異なるAZを指定することで負荷分散を実現している */
        aws_subnet.public_0.id,
        aws_subnet.public_1.id
    ]
    access_logs { /* アクセスログの保存 */
        bucket = aws_s3_bucket.alb_log.id
        enabled = true
    }
    security_groups = [
        module.http_sg.security_group_id,
        module.https_sg.security_group_id,
        module.http_redirect_sg.security_group_id
    ]
}

output "alb_dns_name" {
    value = aws_lb.example.dns_name
}

module "http_sg" {
    source = "./security_group"
    name = "http-sg"
    vpc_id = aws_vpc.example.id
    port = 80
    cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
    source = "./security_group"
    name = "https-sg"
    vpc_id = aws_vpc.example.id
    port = 443
    cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
    source = "./security_group"
    name = "http-redirect-sg"
    vpc_id = aws_vpc.example.id
    port = 8080
    cidr_blocks = ["0.0.0.0/0"]
}

/* ######################### リスナー ######################### */
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = "80" /* 今回はHTTPなので80番ポートに設定 */
    protocol = "HTTP" /* HTTPとHTTPSのみサポートされている */
    default_action {
        type = "fixed-response" /* 固定のHTTPレスポンスを応答（redirect:別のURLにリダイレクト、forward:リクエストを別のターゲットグループに転送） */
        fixed_response {
            content_type = "text/plain"
            message_body = "これは「HTTP」です"
            status_code = "200"
        }
    }
}

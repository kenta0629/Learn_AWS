/* モジュール利用側 */
/* terraform get かterraform initで実行してモジュールを事前に取得する必要あり（それからapply） */
module "web_server" {
    source = "./http_server"
    instance_type = "t3.micro"
}

output "public_dns" {
    value = module.web_server.public_dns
}

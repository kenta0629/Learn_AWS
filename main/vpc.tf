/* VPC */
resource "aws_vpc" "example" {
    cidr_block = "10.0.0.0/16" /* CIDR形式(xx.xx.xx.xx/xx)、後から変更不可 */
    enable_dns_support = true /* DNSによる名前解決 */
    enable_dns_hostnames = true /* DNSホスト名を自動で割り当て */
    tags = {
        Name = "example"
    }
}

/* ######################### パブリックネットワーク ######################### */
/* サブネット（マルチAZ） */
resource "aws_subnet" "public_0" {
    vpc_id = aws_vpc.example.id
    cidr_block = "10.0.1.0/24" /* VPCでは16、サブネットでは24の割り当てにするとわかりやすい */
    map_public_ip_on_launch = true /* パブリックIPの自動割り当て */
    availability_zone = "ap-northeast-1a" /* マルチAZ=複数のアベイラビリティゾーンで構成されたネットワーク */
}

resource "aws_subnet" "public_1" {
    vpc_id = aws_vpc.example.id
    cidr_block = "10.0.2.0/24" /* マルチAZの場合はCIDRブロック重複不可 */
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-1c"
}

/* インターネットゲートウェイ */
resource "aws_internet_gateway" "example" {
    vpc_id = aws_vpc.example.id
}

/* ルーティング（インターネットとデータ通信するための情報） */
/* ルートテーブル */
/* VPC内の通信を有効にするlocalルートが自動で作成される */
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.example.id
}

/* ルート（ルートテーブルの1レコードに値する） */
resource "aws_route" "public" {
    route_table_id = aws_route_table.public.id
    gateway_id = aws_internet_gateway.example.id
    destination_cidr_block = "0.0.0.0/0" /* デフォルトルート（VPC以外への通信をインターネットゲートウェイ経由でインターネットにデータを流す） */
}

/* ルートテーブル関連付け（マルチAZ、サブネット単位で判断） */
/* 関連付けしないとデフォルトテーブルが自動的に使われる（アンチパターン） */
resource "aws_route_table_association" "public_0" {
    subnet_id = aws_subnet.public_0.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
    subnet_id = aws_subnet.public_1.id
    route_table_id = aws_route_table.public.id
}

/* NAT(Network Address Translation) */
/* プライベートネットワークからインターネットにアクセスする方法 */
/* 静的IP(EIP, Elastic IP Address)の設定（マルチAZ） */
resource "aws_eip" "nat_gateway_0" {
    vpc = true
    depends_on = [aws_internet_gateway.example]
}

resource "aws_eip" "nat_gateway_1" {
    vpc = true
    depends_on = [aws_internet_gateway.example]
}

/* NATゲートウェイ（マルチAZ） */
/*
resource "aws_nat_gateway" "example" {
    allocation_id = aws_eip.nat_gateway.id
    subnet_id = aws_subnet.public.id -- プライベートサブネットではないので注意
    depends_on = [aws_internet_gateway.example]
}
*/

/* NATゲートウェイのあるAZで障害が発生するとNATは使用できなくなるため各AZに作成 */
resource "aws_nat_gateway" "nat_gateway_0" {
        allocation_id = aws_eip.nat_gateway_0.id
    subnet_id = aws_subnet.public_0.id
    depends_on = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_1" {
        allocation_id = aws_eip.nat_gateway_1.id
    subnet_id = aws_subnet.public_1.id
    depends_on = [aws_internet_gateway.example]
}

/* ######################### プライベートネットワーク ######################### */
/* サブネット（マルチAZ） */
resource "aws_subnet" "private_0" {
    vpc_id = aws_vpc.example.id
    cidr_block = "10.0.65.0/24"
    availability_zone = "ap-northeast-1a"
    map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
    vpc_id = aws_vpc.example.id
    cidr_block = "10.0.66.0/24"
    availability_zone = "ap-northeast-1c"
    map_public_ip_on_launch = false
}

/* ルートテーブル（マルチAZ、関連付けも） */
resource "aws_route_table" "private_0" {
    vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private_1" {
    vpc_id = aws_vpc.example.id
}

resource "aws_route_table_association" "private_0" {
    subnet_id = aws_subnet.private_0.id
    route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
    subnet_id = aws_subnet.private_1.id
    route_table_id = aws_route_table.private_1.id
}

/* ルート（マルチAZ、NATゲートウェイ経由） */
resource "aws_route" "private_0" {
    route_table_id = aws_route_table.private_0.id
    nat_gateway_id = aws_nat_gateway.nat_gateway_0.id /* NATゲートウェイIDを使用 */
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
    route_table_id = aws_route_table.private_1.id
    nat_gateway_id = aws_nat_gateway.nat_gateway_1.id /* NATゲートウェイIDを使用 */
    destination_cidr_block = "0.0.0.0/0"
}
